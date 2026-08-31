const std = @import("std");
const lexer = @import("lexer.zig");
const meta = @import("meta.zig");

pub const ParseError = error{
    MissingRequiredEnvVar,
    InvalidIntegerValue,
    InvalidFloatValue,
    InvalidBooleanValue,
    InvalidEnumValue,
    UnsupportedType,
};

/// Parses .env string into struct T with ZERO heap allocations (strings are borrowed directly).
pub fn parse(comptime T: type, env_str: []const u8) ParseError!T {
    const info = @typeInfo(T);
    if (info != .@"struct") {
        @compileError("zenv.parse expects a struct type, found " ++ @typeName(T));
    }

    const mapping = if (@hasDecl(T, "zenv") and @hasField(@TypeOf(T.zenv), "mapping"))
        T.zenv.mapping
    else
        .{};

    var result: T = undefined;

    inline for (info.@"struct".fields) |field| {
        const custom_key: ?[]const u8 = if (@hasField(@TypeOf(mapping), field.name))
            @field(mapping, field.name)
        else
            null;

        const maybe_val = findEnvValue(env_str, field.name, custom_key);

        if (maybe_val) |raw_val| {
            @field(result, field.name) = try parseValue(field.type, raw_val);
        } else {
            if (field.default_value_ptr) |ptr| {
                const typed_ptr: *const field.type = @ptrCast(@alignCast(ptr));
                @field(result, field.name) = typed_ptr.*;
            } else if (@typeInfo(field.type) == .optional) {
                @field(result, field.name) = null;
            } else {
                return error.MissingRequiredEnvVar;
            }
        }
    }

    return result;
}

fn findEnvValue(env_str: []const u8, comptime field_name: []const u8, comptime custom_key: ?[]const u8) ?[]const u8 {
    var it = lexer.EnvIterator.init(env_str);
    while (it.next()) |pair| {
        if (meta.matchesKey(field_name, custom_key, pair.key)) {
            return pair.value;
        }
    }
    return null;
}

fn parseValue(comptime FieldType: type, raw: []const u8) ParseError!FieldType {
    const type_info = @typeInfo(FieldType);

    switch (type_info) {
        .int => {
            return std.fmt.parseInt(FieldType, raw, 10) catch error.InvalidIntegerValue;
        },
        .float => {
            return std.fmt.parseFloat(FieldType, raw) catch error.InvalidFloatValue;
        },
        .bool => {
            if (std.ascii.eqlIgnoreCase(raw, "true") or
                std.ascii.eqlIgnoreCase(raw, "1") or
                std.ascii.eqlIgnoreCase(raw, "yes") or
                std.ascii.eqlIgnoreCase(raw, "on"))
            {
                return true;
            } else if (std.ascii.eqlIgnoreCase(raw, "false") or
                std.ascii.eqlIgnoreCase(raw, "0") or
                std.ascii.eqlIgnoreCase(raw, "no") or
                std.ascii.eqlIgnoreCase(raw, "off"))
            {
                return false;
            } else {
                return error.InvalidBooleanValue;
            }
        },
        .pointer => |ptr| {
            if (ptr.size == .slice and ptr.child == u8) {
                return raw; // Borrow slice directly!
            }
            return error.UnsupportedType;
        },
        .@"enum" => {
            inline for (@typeInfo(FieldType).@"enum".fields) |f| {
                if (std.ascii.eqlIgnoreCase(f.name, raw)) {
                    return @enumFromInt(f.value);
                }
            }
            return error.InvalidEnumValue;
        },
        .optional => |opt| {
            if (raw.len == 0) return null;
            return try parseValue(opt.child, raw);
        },
        else => {
            return error.UnsupportedType;
        },
    }
}

test "zero-alloc struct parsing" {
    const ServerConfig = struct {
        host: []const u8 = "127.0.0.1",
        port: u16 = 8080,
        database_url: []const u8,
        debug: bool = false,
        workers: ?u32 = null,
        log_level: enum { debug, info, warn, err } = .info,

        pub const zenv = .{
            .mapping = .{
                .database_url = "DB_URL",
            },
        };
    };

    const env_text =
        \\HOST=0.0.0.0
        \\PORT=3000
        \\DB_URL="postgresql://user:pass@localhost:5432/mydb"
        \\DEBUG=true
        \\LOG_LEVEL=warn
    ;

    const cfg = try parse(ServerConfig, env_text);

    try std.testing.expectEqualStrings("0.0.0.0", cfg.host);
    try std.testing.expectEqual(@as(u16, 3000), cfg.port);
    try std.testing.expectEqualStrings("postgresql://user:pass@localhost:5432/mydb", cfg.database_url);
    try std.testing.expectEqual(true, cfg.debug);
    try std.testing.expectEqual(@as(?u32, null), cfg.workers);
    try std.testing.expectEqual(cfg.log_level, .warn);
}
