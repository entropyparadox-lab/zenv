const std = @import("std");
const Allocator = std.mem.Allocator;
const parser = @import("parser.zig");
const meta = @import("meta.zig");

pub fn loadFile(comptime T: type, allocator: Allocator, path: []const u8) !T {
    const fd = std.posix.openat(std.posix.AT.FDCWD, path, .{}, 0) catch return error.FileNotFound;
    defer _ = std.posix.system.close(fd);

    var buf: [65536]u8 = undefined;
    const bytes_read = std.posix.read(fd, &buf) catch return error.FileReadError;
    const content = try allocator.dupe(u8, buf[0..bytes_read]);
    return parser.parse(T, content);
}

pub fn loadOrEmpty(comptime T: type, allocator: Allocator, path: []const u8) !T {
    if (loadFile(T, allocator, path)) |cfg| {
        return cfg;
    } else |_| {
        return parser.parse(T, "");
    }
}
