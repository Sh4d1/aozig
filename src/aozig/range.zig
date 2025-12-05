const std = @import("std");

pub const RangeParseError = error{InvalidFormat};

fn assertInt(comptime T: type) void {
    const info = @typeInfo(T);
    if (info != .int and info != .comptime_int) {
        @compileError("Range only supports integer types");
    }
}

/// Inclusive integer range utilities.
pub fn Range(comptime T: type) type {
    assertInt(T);
    return struct {
        const Self = @This();

        start: T,
        end: T,

        /// Normalizes the endpoints so that `start <= end`.
        pub fn init(a: T, b: T) Self {
            return if (a <= b) .{ .start = a, .end = b } else .{ .start = b, .end = a };
        }

        /// Checks whether the value falls inside the range (inclusive).
        pub fn contains(self: Self, value: T) bool {
            return value >= self.start and value <= self.end;
        }

        /// Returns true when the ranges overlap.
        pub fn intersects(self: Self, other: Self) bool {
            return self.start <= other.end and other.start <= self.end;
        }

        /// Returns the merged range when overlapping, otherwise null.
        pub fn merge(self: Self, other: Self) ?Self {
            if (!self.intersects(other)) return null;
            return .{
                .start = if (self.start < other.start) self.start else other.start,
                .end = if (self.end > other.end) self.end else other.end,
            };
        }

        /// Number of integers contained in the range.
        pub fn len(self: Self) usize {
            return @as(usize, @intCast(self.end - self.start)) + 1;
        }

        /// Iterator that yields every integer in the inclusive range.
        pub fn iter(self: Self) Iterator {
            return .{
                .current = self.start,
                .end = self.end,
                .done = false,
            };
        }

        pub const Iterator = struct {
            current: T,
            end: T,
            done: bool,

            pub fn next(self: *Iterator) ?T {
                if (self.done) return null;
                const value = self.current;
                if (value == self.end) {
                    self.done = true;
                } else {
                    self.current += 1;
                }
                return value;
            }
        };

        /// Parses formats such as "1-4" or "1;4" depending on `sep`.
        pub fn parse(text: []const u8, sep: u8) !Self {
            const trimmed = std.mem.trim(u8, text, " \n");
            if (trimmed.len == 0) return RangeParseError.InvalidFormat;
            var parts = std.mem.splitScalar(u8, trimmed, sep);
            const left_raw = parts.next() orelse return RangeParseError.InvalidFormat;
            const right_raw = parts.next() orelse return RangeParseError.InvalidFormat;
            if (parts.next()) |_| return RangeParseError.InvalidFormat;
            const left_text = std.mem.trim(u8, left_raw, " ");
            const right_text = std.mem.trim(u8, right_raw, " ");
            if (left_text.len == 0 or right_text.len == 0) return RangeParseError.InvalidFormat;
            const left = try std.fmt.parseInt(T, left_text, 10);
            const right = try std.fmt.parseInt(T, right_text, 10);
            return init(left, right);
        }
    };
}

test "range utilities" {
    const R = Range(i32);
    const r = R.init(3, 7);
    try std.testing.expect(r.contains(5));
    try std.testing.expect(!r.contains(9));
    try std.testing.expectEqual(@as(usize, 5), r.len());

    const r2 = R.init(6, 10);
    try std.testing.expect(r.intersects(r2));
    try std.testing.expectEqual(@as(?R, R.init(3, 10)), r.merge(r2));
    try std.testing.expectEqual(@as(?R, null), r.merge(R.init(20, 30)));
    try std.testing.expectEqual(R.init(1, 43), try R.parse("1-43", '-'));
    try std.testing.expectEqual(R.init(1, 45), try R.parse(" 1 ; 45 ", ';'));

    var it = r.iter();
    var expected: i32 = 3;
    while (it.next()) |value| : (expected += 1) {
        try std.testing.expectEqual(expected, value);
    }
    try std.testing.expectEqual(@as(i32, 8), expected);
}
