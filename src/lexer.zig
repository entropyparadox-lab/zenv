const std = @import("std");

pub const EnvPair = struct {
    key: []const u8,
    value: []const u8,
};

pub const EnvIterator = struct {
    bytes: []const u8,
    cursor: usize = 0,

    pub fn init(bytes: []const u8) EnvIterator {
        return .{ .bytes = bytes, .cursor = 0 };
    }

    pub fn next(self: *EnvIterator) ?EnvPair {
        while (self.cursor < self.bytes.len) {
            const line_start = self.cursor;
            var line_end = self.cursor;

            while (line_end < self.bytes.len and self.bytes[line_end] != '\n') : (line_end += 1) {}
            self.cursor = if (line_end < self.bytes.len) line_end + 1 else self.bytes.len;

            var raw_line = self.bytes[line_start..line_end];
            // Strip trailing carriage return if \r\n
            if (raw_line.len > 0 and raw_line[raw_line.len - 1] == '\r') {
                raw_line = raw_line[0 .. raw_line.len - 1];
            }

            const trimmed = std.mem.trim(u8, raw_line, " \t");
            if (trimmed.len == 0 or trimmed[0] == '#') continue;

            // Strip optional 'export ' prefix
            var clean_line = trimmed;
            if (std.mem.startsWith(u8, clean_line, "export ")) {
                clean_line = std.mem.trim(u8, clean_line[7..], " \t");
            }

            // Find '=' delimiter
            const eq_idx = std.mem.indexOfScalar(u8, clean_line, '=') orelse continue;
            const key = std.mem.trim(u8, clean_line[0..eq_idx], " \t");
            if (key.len == 0) continue;

            var raw_val = std.mem.trim(u8, clean_line[eq_idx + 1 ..], " \t");

            // Strip quotes
            if (raw_val.len >= 2 and ((raw_val[0] == '"' and raw_val[raw_val.len - 1] == '"') or
                (raw_val[0] == '\'' and raw_val[raw_val.len - 1] == '\'')))
            {
                raw_val = raw_val[1 .. raw_val.len - 1];
            } else {
                // For unquoted, strip trailing inline comments
                if (std.mem.indexOfScalar(u8, raw_val, '#')) |comment_idx| {
                    raw_val = std.mem.trim(u8, raw_val[0..comment_idx], " \t");
                }
            }

            return EnvPair{
                .key = key,
                .value = raw_val,
            };
        }
        return null;
    }
};

test "lexer parsing pairs" {
    const raw_env =
        \\# Global Configuration
        \\export SERVER_HOST=0.0.0.0 # bind address
        \\SERVER_PORT=9000
        \\
        \\DEBUG="true"
        \\API_SECRET='secret_token_123'
        \\EMPTY_VAL=
    ;

    var it = EnvIterator.init(raw_env);

    const p1 = it.next().?;
    try std.testing.expectEqualStrings("SERVER_HOST", p1.key);
    try std.testing.expectEqualStrings("0.0.0.0", p1.value);

    const p2 = it.next().?;
    try std.testing.expectEqualStrings("SERVER_PORT", p2.key);
    try std.testing.expectEqualStrings("9000", p2.value);

    const p3 = it.next().?;
    try std.testing.expectEqualStrings("DEBUG", p3.key);
    try std.testing.expectEqualStrings("true", p3.value);

    const p4 = it.next().?;
    try std.testing.expectEqualStrings("API_SECRET", p4.key);
    try std.testing.expectEqualStrings("secret_token_123", p4.value);

    const p5 = it.next().?;
    try std.testing.expectEqualStrings("EMPTY_VAL", p5.key);
    try std.testing.expectEqualStrings("", p5.value);

    try std.testing.expect(it.next() == null);
}
