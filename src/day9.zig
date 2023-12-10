const std = @import("std");
pub const data = @embedFile("day9.txt");
const alloc = std.heap.page_allocator;

pub fn solve(input: []i32, last: bool) []i32 {
    var l = input;
    var single = std.ArrayList(i32).init(alloc);
    if (last) {
        single.append(@intCast(input[input.len - 1])) catch unreachable;
    } else {
        single.append(@intCast(input[0])) catch unreachable;
    }
    while (true) {
        var new_line = std.ArrayList(i32).init(alloc);
        for (l[1..], 1..) |_, i| {
            new_line.append(@intCast(l[i] - l[i - 1])) catch unreachable;
        }
        if (last) {
            single.append(@intCast(new_line.getLast())) catch unreachable;
        } else {
            single.append(@intCast(new_line.items[0])) catch unreachable;
        }
        var all_zero: bool = true;
        for (new_line.items) |d| {
            if (d != 0) {
                all_zero = false;
                break;
            }
        }
        if (!all_zero) {
            l = new_line.toOwnedSlice() catch unreachable;
            continue;
        }
        return single.toOwnedSlice() catch unreachable;
    }
}

pub fn solve1(input: [][]i32) i32 {
    var res: i32 = 0;
    for (input) |i| {
        for (solve(i, true)) |r| {
            res += r;
        }
    }
    return res;
}

pub fn solve2(input: [][]i32) i32 {
    var res: i32 = 0;
    for (input) |i| {
        for (solve(i, false), 0..) |r, j| {
            if (j % 2 == 0) {
                res += r;
            } else {
                res -= r;
            }
        }
    }
    return res;
}

pub fn parse(input: []const u8) ![][]i32 {
    var res = std.ArrayList([]i32).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |l| {
        var split = std.mem.tokenizeScalar(u8, l, ' ');
        var line = std.ArrayList(i32).init(alloc);
        while (split.next()) |d| {
            try line.append(try std.fmt.parseInt(i32, d, 10));
        }
        try res.append(try line.toOwnedSlice());
    }
    return try res.toOwnedSlice();
}

pub fn main() !void {
    const input = try parse(data);
    const input2 = try parse(data);
    std.debug.print("Part1: {}\n", .{solve1(input)});
    std.debug.print("Part2: {}\n", .{solve2(input2)});
}

const test_data =
    \\ 0 3 6 9 12 15
    \\ 1 3 6 10 15 21
    \\ 10 13 16 21 30 45
;

test "test-1" {
    const res: i32 = solve1(try parse(test_data));
    try std.testing.expectEqual(res, 114);
}

test "test-2" {
    const res: i32 = solve2(try parse(test_data));
    try std.testing.expectEqual(res, 2);
}
