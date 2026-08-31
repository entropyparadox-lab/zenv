const std = @import("std");
const Allocator = std.mem.Allocator;
const parser = @import("parser.zig");
const meta = @import("meta.zig");

pub fn loadFile(comptime T: type, allocator: Allocator, path: []const u8) !T {
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const max_size: usize = 10 * 1024 * 1024; // 10MB
    const content = try file.readToEndAlloc(allocator, max_size);
    // Note: the caller owns the memory of content if strings are borrowed.
    return parser.parse(T, content);
}

pub fn loadOrEmpty(comptime T: type, allocator: Allocator, path: []const u8) !T {
    if (loadFile(T, allocator, path)) |cfg| {
        return cfg;
    } else |_| {
        return parser.parse(T, "");
    }
}
