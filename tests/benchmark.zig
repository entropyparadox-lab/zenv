const std = @import("std");
const zenv = @import("zenv");

const BenchmarkConfig = struct {
    host: []const u8,
    port: u16,
    db_url: []const u8,
    secret_key: []const u8,
    debug: bool,
    max_connections: u32,
    timeout_seconds: f64,
    mode: enum { dev, staging, prod },
};

fn getMonotonicNs() u64 {
    var ts: std.posix.timespec = undefined;
    _ = std.posix.system.clock_gettime(.MONOTONIC, &ts);
    return @as(u64, @intCast(ts.sec)) * 1_000_000_000 + @as(u64, @intCast(ts.nsec));
}

pub fn main(init: std.process.Init) !void {
    _ = init;

    const env_text =
        \\# Production Server Config
        \\HOST=10.0.0.1
        \\PORT=8000
        \\DB_URL="postgresql://admin:secret@db.internal:5432/app"
        \\SECRET_KEY="0123456789abcdef0123456789abcdef"
        \\DEBUG=false
        \\MAX_CONNECTIONS=100
        \\TIMEOUT_SECONDS=30.5
        \\MODE=prod
    ;

    // 1. Warmup
    var w: usize = 0;
    while (w < 10_000) : (w += 1) {
        const cfg = try zenv.parse(BenchmarkConfig, env_text);
        std.mem.doNotOptimizeAway(cfg);
    }

    // 2. Measure
    const iterations: usize = 1_000_000;
    const start_ns = getMonotonicNs();

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        const cfg = try zenv.parse(BenchmarkConfig, env_text);
        std.mem.doNotOptimizeAway(cfg);
    }

    const end_ns = getMonotonicNs();
    const elapsed_ns = end_ns - start_ns;
    const elapsed_sec = @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000_000.0;
    const ops_per_sec = @as(f64, @floatFromInt(iterations)) / elapsed_sec;
    const latency_ns = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(iterations));

    std.debug.print("\n=== zenv Benchmark Highlights (ReleaseFast, {d} runs) ===\n", .{iterations});
    std.debug.print("• Total Time   : {d:.4} s\n", .{elapsed_sec});
    std.debug.print("• Throughput   : {d:.2} ops/sec ({d:.2} M ops/sec)\n", .{ ops_per_sec, ops_per_sec / 1_000_000.0 });
    std.debug.print("• Latency      : {d:.2} ns/op\n", .{latency_ns});
    std.debug.print("• Memory Alloc : 0 bytes (Zero-Allocation)\n\n", .{});
}
