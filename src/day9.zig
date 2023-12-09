const std = @import("std");
const data = @embedFile("day9.txt");
const alloc = std.heap.page_allocator;

pub fn solve1(input: [][]i32) !i32 {
    var res: i32 = 0;
    for (input) |l| {
        var new_l = l;
        var all_last = std.ArrayList(i32).init(alloc);
        try all_last.append(@intCast(l[l.len - 1]));
        while (true) {
            var new_line = std.ArrayList(i32).init(alloc);
            for (new_l[1..], 1..) |_, i| {
                try new_line.append(@intCast(new_l[i] - new_l[i - 1]));
            }
            try all_last.append(@intCast(new_line.getLast()));
            var all_zero: bool = true;
            for (new_line.items) |d| {
                if (d != 0) {
                    all_zero = false;
                    break;
                }
            }
            if (!all_zero) {
                new_l = try new_line.toOwnedSlice();
                continue;
            }

            for (all_last.items) |d| {
                res += d;
            }
            break;
        }
    }
    return res;
}

pub fn solve2(input: [][]i32) !i32 {
    var res: i32 = 0;
    for (input) |l| {
        var new_l = l;
        var all_last = std.ArrayList(i32).init(alloc);
        res += l[0];
        while (true) {
            var new_line = std.ArrayList(i32).init(alloc);
            for (new_l[1..], 1..) |_, i| {
                try new_line.append(@intCast(new_l[i] - new_l[i - 1]));
            }
            try all_last.append(@intCast(new_line.items[0]));
            var all_zero: bool = true;
            for (new_line.items) |d| {
                if (d != 0) {
                    all_zero = false;
                    break;
                }
            }
            if (!all_zero) {
                new_l = try new_line.toOwnedSlice();
                continue;
            }

            for (all_last.items, 0..) |d, i| {
                if (i % 2 == 0) {
                    res -= d;
                } else {
                    res += d;
                }
            }
            break;
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
    std.debug.print("Part1: {}\n", .{try solve1(input)});
    std.debug.print("Part2: {}\n", .{try solve2(input2)});
}

const test_data =
    \\ 0 3 6 9 12 15
    \\ 1 3 6 10 15 21
    \\ 10 13 16 21 30 45
;

test "test-1" {
    const res: i32 = try solve1(try parse(test_data));
    try std.testing.expectEqual(res, 114);
}

test "test-2" {
    const res: i32 = try solve2(try parse(test_data));
    try std.testing.expectEqual(res, 2);
}
