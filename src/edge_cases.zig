const std = @import("std");
const zenv = @import("root.zig");
const testing = std.testing;

// ============================================================================
// 1. Missing Required Environment Variables
// ============================================================================

test "zenv: missing required variable returns error" {
    const Config = struct {
        api_key: []const u8, // No default -> Required
        port: u16 = 8080,
    };

    const env_text = "PORT=9000";
    try testing.expectError(error.MissingRequiredEnvVar, zenv.parse(Config, env_text));
}

// ============================================================================
// 2. Type Parse Errors
// ============================================================================

test "zenv: invalid integer/float/bool/enum returns specific errors" {
    const StrictConfig = struct {
        port: u16,
        rate: f64,
        active: bool,
        env: enum { development, staging, production },
    };

    // Invalid int
    try testing.expectError(error.InvalidIntegerValue, zenv.parse(StrictConfig,
        \\PORT=not_an_int
        \\RATE=1.5
        \\ACTIVE=true
        \\ENV=production
    ));

    // Invalid float
    try testing.expectError(error.InvalidFloatValue, zenv.parse(StrictConfig,
        \\PORT=8080
        \\RATE=not_a_float
        \\ACTIVE=true
        \\ENV=production
    ));

    // Invalid bool
    try testing.expectError(error.InvalidBooleanValue, zenv.parse(StrictConfig,
        \\PORT=8080
        \\RATE=1.5
        \\ACTIVE=maybe
        \\ENV=production
    ));

    // Invalid enum
    try testing.expectError(error.InvalidEnumValue, zenv.parse(StrictConfig,
        \\PORT=8080
        \\RATE=1.5
        \\ACTIVE=true
        \\ENV=local_dev
    ));
}

// ============================================================================
// 3. Comments, Quotes, and Whitespace Handling
// ============================================================================

test "zenv: inline comments and quotes" {
    const AppConfig = struct {
        app_name: []const u8,
        secret: []const u8,
        count: u32,
        debug_mode: bool,
    };

    const env_content =
        \\# Global environment configuration
        \\APP_NAME="Entropy Paradox Service"   # double quoted with spaces
        \\SECRET='single-quoted-secret#with-hash' # single quoted
        \\COUNT=500 # trailing comment
        \\DEBUG_MODE=yes # boolean yes
    ;

    const cfg = try zenv.parse(AppConfig, env_content);
    try testing.expectEqualStrings("Entropy Paradox Service", cfg.app_name);
    try testing.expectEqualStrings("single-quoted-secret#with-hash", cfg.secret);
    try testing.expectEqual(@as(u32, 500), cfg.count);
    try testing.expectEqual(true, cfg.debug_mode);
}

// ============================================================================
// 4. Boolean Variants (1/0, on/off, true/false, yes/no)
// ============================================================================

test "zenv: all boolean truthy and falsy aliases" {
    const BoolMatrix = struct {
        b1: bool,
        b2: bool,
        b3: bool,
        b4: bool,
        b5: bool,
        b6: bool,
        b7: bool,
        b8: bool,
    };

    const env_text =
        \\B1=1
        \\B2=true
        \\B3=yes
        \\B4=on
        \\B5=0
        \\B6=false
        \\B7=no
        \\B8=off
    ;

    const cfg = try zenv.parse(BoolMatrix, env_text);
    try testing.expect(cfg.b1);
    try testing.expect(cfg.b2);
    try testing.expect(cfg.b3);
    try testing.expect(cfg.b4);
    try testing.expect(!cfg.b5);
    try testing.expect(!cfg.b6);
    try testing.expect(!cfg.b7);
    try testing.expect(!cfg.b8);
}
