const std = @import("std");

/// Converts snake_case or camelCase identifier to UPPER_SNAKE_CASE at compile time.
pub fn toUpperSnakeCase(comptime str: []const u8) []const u8 {
    const static = struct {
        const transformed = blk: {
            var buf: [str.len * 2]u8 = undefined;
            var out_idx: usize = 0;

            for (str, 0..) |c, i| {
                if (c >= 'a' and c <= 'z') {
                    buf[out_idx] = c - ('a' - 'A');
                    out_idx += 1;
                } else if (c >= 'A' and c <= 'Z') {
                    if (i > 0 and str[i - 1] != '_' and !(str[i - 1] >= 'A' and str[i - 1] <= 'Z')) {
                        buf[out_idx] = '_';
                        out_idx += 1;
                    }
                    buf[out_idx] = c;
                    out_idx += 1;
                } else if (c == '-') {
                    buf[out_idx] = '_';
                    out_idx += 1;
                } else {
                    buf[out_idx] = c;
                    out_idx += 1;
                }
            }

            var final_buf: [out_idx]u8 = undefined;
            @memcpy(&final_buf, buf[0..out_idx]);
            break :blk final_buf;
        };
    };
    return &static.transformed;
}

pub fn matchesKey(comptime field_name: []const u8, comptime custom_mapping: ?[]const u8, key: []const u8) bool {
    if (custom_mapping) |m| {
        if (std.ascii.eqlIgnoreCase(m, key)) return true;
    }
    if (std.ascii.eqlIgnoreCase(field_name, key)) return true;
    const upper_snake = toUpperSnakeCase(field_name);
    if (std.ascii.eqlIgnoreCase(upper_snake, key)) return true;
    return false;
}

test "toUpperSnakeCase" {
    try std.testing.expectEqualStrings("PORT", toUpperSnakeCase("port"));
    try std.testing.expectEqualStrings("SERVER_PORT", toUpperSnakeCase("server_port"));
    try std.testing.expectEqualStrings("DATABASE_URL", toUpperSnakeCase("databaseUrl"));
    try std.testing.expectEqualStrings("API_KEY", toUpperSnakeCase("api-key"));
}
