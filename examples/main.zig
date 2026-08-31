const std = @import("std");
const zenv = @import("zenv");

const AppConfig = struct {
    host: []const u8 = "127.0.0.1",
    port: u16 = 8080,
    database_url: []const u8,
    jwt_secret: []const u8,
    debug: bool = false,
    workers: u32 = 4,
    log_level: enum { debug, info, warn, err } = .info,

    pub const zenv = .{
        .mapping = .{
            .database_url = "DB_URL",
            .jwt_secret = "APP_SECRET",
        },
    };
};

pub fn main(init: std.process.Init) !void {
    _ = init;

    const sample_env =
        \\# App Configuration
        \\HOST=0.0.0.0
        \\PORT=9090
        \\DB_URL="postgres://user:secret@localhost:5432/production_db"
        \\APP_SECRET="super-secret-jwt-key-32-bytes"
        \\DEBUG=true
        \\WORKERS=8
        \\LOG_LEVEL=info
    ;

    // Zero-allocation struct parse directly from string buffer!
    const config = try zenv.parse(AppConfig, sample_env);

    std.debug.print("🌿 zenv: Loaded Configuration (Zero Heap Allocations)\n", .{});
    std.debug.print("----------------------------------------------------\n", .{});
    std.debug.print("• Host        : {s}\n", .{config.host});
    std.debug.print("• Port        : {d}\n", .{config.port});
    std.debug.print("• DB URL      : {s}\n", .{config.database_url});
    std.debug.print("• JWT Secret  : {s}\n", .{config.jwt_secret});
    std.debug.print("• Debug       : {}\n", .{config.debug});
    std.debug.print("• Workers     : {d}\n", .{config.workers});
    std.debug.print("• Log Level   : {s}\n", .{@tagName(config.log_level)});
}
