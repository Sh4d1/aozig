const std = @import("std");

pub var alloc: std.mem.Allocator = std.heap.page_allocator;

pub fn parse(input: []const u8) ![][]u8 {
    var res: std.array_list.Aligned([]u8, null) = .empty;
    defer res.deinit(alloc);
    var lines = std.mem.splitAny(u8, input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var tmp: std.array_list.Aligned(u8, null) = .empty;
        for (line) |c| {
            try tmp.append(alloc, c - '0');
        }
        try res.append(alloc, try tmp.toOwnedSlice(alloc));
        tmp.deinit(alloc);
    }
    return try res.toOwnedSlice(alloc);
}

pub fn solve1(input: [][]u8) usize {
    var res: usize = 0;
    for (input) |bat| {
        var max_left: usize = 0;
        var max_right: usize = 0;
        var i: usize = 0;
        while (i < bat.len) : (i += 1) {
            if (bat[i] > max_left and i < bat.len - 1) {
                max_left = bat[i];
                max_right = 0;
            } else if (bat[i] > max_right) {
                max_right = bat[i];
            }
        }
        res += max_left * 10 + max_right;
    }
    return res;
}

pub fn solve2(input: [][]u8) usize {
    const size = 12;
    var res: usize = 0;
    for (input) |bat| {
        var start: usize = 0;
        var value: usize = 0;
        var pos: usize = 0;
        while (pos < size) : (pos += 1) {
            const remaining = size - pos;
            const last_start = bat.len - remaining;
            var idx = start;
            var best = bat[idx];
            var i = idx + 1;
            while (i <= last_start) : (i += 1) {
                if (bat[i] > best) {
                    best = bat[i];
                    idx = i;
                    if (best == 9) break;
                }
            }
            value = value * 10 + best;
            start = idx + 1;
        }
        res += value;
    }
    return res;
}

test "example" {
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;
    const parsed = try parse(input);
    try std.testing.expectEqual(@as(usize, 357), solve1(parsed));
    try std.testing.expectEqual(@as(usize, 3121910778619), solve2(parsed));
}
