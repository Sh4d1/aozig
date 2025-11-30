const std = @import("std");
const aozig = @import("aozig");

pub var alloc: std.mem.Allocator = undefined;

pub fn parse(input: []const u8) !void {{
    _ = input;
    // TODO: Parse input
}}

pub fn solve1(_: void) usize {{
    // TODO: Solve part 1
    return 0;
}}

pub fn solve2(_: void) usize {{
    // TODO: Solve part 2
    return 0;
}}

test "example" {{
    const input =
        \\
    ;
    _ = try parse(input);
    try std.testing.expectEqual(@as(usize, 0), solve1({{}}));
    try std.testing.expectEqual(@as(usize, 0), solve2({{}}));
}}
