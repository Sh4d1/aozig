const std = @import("std");
pub var alloc = std.heap.page_allocator;

pub fn findReflection(grid: [][]const u8, vertical: bool, mistakes: usize) usize {
    const x_len = if (!vertical) grid.len else grid[0].len;
    const y_len = if (!vertical) grid[0].len else grid.len;

    outer: for (1..x_len) |i| {
        var found_mistakes: usize = 0;
        for (0..x_len) |j| {
            if (j + i >= x_len or i < j + 1) break;
            for (0..y_len) |k| {
                const l = if (!vertical) grid[j + i][k] else grid[k][j + i];
                const r = if (!vertical) grid[i - j - 1][k] else grid[k][i - j - 1];
                if (l != r) {
                    found_mistakes += 1;
                    if (found_mistakes > mistakes) continue :outer;
                }
            }
        }
        if (found_mistakes != mistakes) continue;
        return i;
    }
    return 0;
}

pub fn solve1(input: [][][]const u8) !usize {
    var res: usize = 0;
    for (input) |grid| {
        const r = findReflection(grid, false, 0);
        if (r != 0) res += 100 * r;
        if (r == 0) res += findReflection(grid, true, 0);
    }
    return res;
}

pub fn solve2(input: [][][]const u8) !usize {
    var res: usize = 0;
    for (input) |grid| {
        const r = findReflection(grid, false, 1);
        if (r != 0) res += 100 * r;
        if (r == 0) res += findReflection(grid, true, 1);
    }
    return res;
}

pub fn parse(input: []const u8) ![][][]const u8 {
    var res = std.ArrayList([][]const u8).init(alloc);
    var patterns = std.mem.splitSequence(u8, input, "\n\n");

    while (patterns.next()) |lines| {
        var l = std.mem.tokenizeScalar(u8, lines, '\n');
        var grid = std.ArrayList([]const u8).init(alloc);

        while (l.next()) |line| {
            try grid.append(line);
        }
        try res.append(try grid.toOwnedSlice());
    }
    return try res.toOwnedSlice();
}

const test_data =
    \\#.##..##.
    \\..#.##.#.
    \\##......#
    \\##......#
    \\..#.##.#.
    \\..##..##.
    \\#.#.##.#.
    \\
    \\#...##..#
    \\#....#..#
    \\..##..###
    \\#####.##.
    \\#####.##.
    \\..##..###
    \\#....#..#
;

test "test-1" {
    const res: usize = try solve1(try parse(test_data));
    try std.testing.expectEqual(res, 405);
}

test "test-2" {
    const res: usize = try solve2(try parse(test_data));
    try std.testing.expectEqual(res, 400);
}
