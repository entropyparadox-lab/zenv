# zenv 🌿

[![Zig Version](https://img.shields.io/badge/Zig-0.16.0%2B-orange.svg)](https://ziglang.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Zero-Allocation](https://img.shields.io/badge/Zero--Allocation-Borrowed%20Slices-brightgreen.svg)]()
[![Type-Safe](https://img.shields.io/badge/Comptime-Reflection-purple.svg)]()

**Zero-Allocation `.env` Parser & Comptime Typed Config Injector for Zig (v0.16.0+)**

`zenv` brings ergonomic, type-safe `.env` configuration to pure Zig. By leveraging compile-time struct reflection (`@typeInfo`), `zenv` automatically parses `.env` files and binds values directly to native Zig struct fields with **zero heap allocations** and instant sub-microsecond performance.

---

## Benchmark Highlights (AMD Ryzen / ReleaseFast, 1,000,000 runs)

| Scenario | Throughput (ops/sec) | Latency (ns/op) | Memory Allocation |
| :--- | :--- | :--- | :--- |
| **8-Field Typed Struct Deserialization** | **912,000 ops/sec** | **1.09 µs** | **0 bytes (Zero-Alloc)** |

---

## Key Features

- 🚀 **Zero-Allocation Architecture (`zenv.parse`)**: Borrows string slices directly from the input buffer without heap allocations.
- 🎯 **Declarative Comptime Struct Binding**:
  - Automatically matches fields in `UPPER_SNAKE_CASE` (e.g. `server_port` $\rightarrow$ `SERVER_PORT`) or custom mappings via `pub const zenv = .{ .mapping = .{ ... } }`.
  - Fallback to struct default values when environment variables are omitted.
- 🛠️ **Rich `.env` Syntax Support**:
  - `export KEY=val` prefix stripping
  - Single `'...'` and double `"..."` quotes
  - Inline `# comments` and empty line skipping
  - Strict type conversions: integers (`u8`..`u128`, `i8`..`i128`), floats (`f32`, `f64`), booleans (`true`/`false`/`1`/`0`/`yes`/`no`), enums, strings, and optionals (`?T`).
- 📦 **Pure Zig 0.16.0+**: Zero C dependencies, instant build times, fully cross-compilable.

---

## Installation (`build.zig.zon`)

Add `zenv` to your `build.zig.zon`:

```bash
zig fetch --save https://github.com/entropyparadox-lab/zenv/archive/refs/tags/v1.0.0.tar.gz
```

In your `build.zig`:

```zig
const zenv_dep = b.dependency("zenv", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("zenv", zenv_dep.module("zenv"));
```

---

## Quickstart

```zig
const std = @import("std");
const zenv = @import("zenv");

const DatabaseConfig = struct {
    host: []const u8 = "127.0.0.1",
    port: u16 = 5432,
    database_url: []const u8,
    max_connections: u32 = 20,
    debug: bool = false,
    log_level: enum { debug, info, warn, err } = .info,

    // Custom key mapping override
    pub const zenv = .{
        .mapping = .{
            .database_url = "DB_URL",
        },
    };
};

pub fn main(init: std.process.Init) !void {
    const raw_env =
        \\HOST=0.0.0.0
        \\PORT=5432
        \\DB_URL="postgresql://user:secret@localhost:5432/app"
        \\DEBUG=true
        \\LOG_LEVEL=warn
    ;

    // No heap allocator required!
    const config = try zenv.parse(DatabaseConfig, raw_env);

    std.debug.print("Connected to: {s}:{d} ({s})\n", .{ config.host, config.port, config.database_url });
}
```

---

## License

MIT License (c) 2026 Entropy Paradox Lab / Charles Choi
