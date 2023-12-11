const std = @import("std");
pub var alloc = std.heap.page_allocator;

pub fn solve(input: []i32, last: bool) ![]i32 {
    var l = input;
    var single = std.ArrayList(i32).init(alloc);
    if (last) {
        try single.append(@intCast(input[input.len - 1]));
    } else {
        try single.append(@intCast(input[0]));
    }
    while (true) {
        var new_line = std.ArrayList(i32).init(alloc);
        for (l[1..], 1..) |_, i| {
            try new_line.append(@intCast(l[i] - l[i - 1]));
        }
        if (last) {
            try single.append(@intCast(new_line.getLast()));
        } else {
            try single.append(@intCast(new_line.items[0]));
        }
        var all_zero: bool = true;
        for (new_line.items) |d| {
            if (d != 0) {
                all_zero = false;
                break;
            }
        }
        if (!all_zero) {
            l = try new_line.toOwnedSlice();
            continue;
        }
        return try single.toOwnedSlice();
    }
}

pub fn solve1(input: [][]i32) !i32 {
    var res: i32 = 0;
    for (input) |i| {
        for (try solve(i, true)) |r| {
            res += r;
        }
    }
    return res;
}

pub fn solve2(input: [][]i32) !i32 {
    var res: i32 = 0;
    for (input) |i| {
        for (try solve(i, false), 0..) |r, j| {
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
