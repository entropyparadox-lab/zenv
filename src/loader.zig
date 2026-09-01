const std = @import("std");
const Allocator = std.mem.Allocator;
const parser = @import("parser.zig");
const meta = @import("meta.zig");

pub fn loadFile(comptime T: type, allocator: Allocator, path: []const u8) !T {
    const path_z = try allocator.dupeZ(u8, path);
    defer allocator.free(path_z);

    const fd_raw = std.posix.system.open(path_z.ptr, std.mem.zeroes(std.posix.system.O), 0);
    if (@as(isize, @bitCast(fd_raw)) < 0) return error.FileNotFound;
    const fd: i32 = @intCast(fd_raw);
    defer _ = std.posix.system.close(fd);

    var buf: [65536]u8 = undefined;
    const bytes_read_raw = std.posix.system.read(fd, &buf, buf.len);
    if (@as(isize, @bitCast(bytes_read_raw)) < 0) return error.FileReadError;
    const bytes_read: usize = @intCast(bytes_read_raw);
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
