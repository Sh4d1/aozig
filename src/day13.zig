const std = @import("std");
pub var alloc = std.heap.page_allocator;

pub fn isReflection(grid: [][]const u8, vertical: bool, i: usize) bool {
    if (!vertical) {
        var eql: bool = false;
        for (0..grid.len) |j| {
            if (i + j + 1 >= grid.len) break;
            if (i < j) break;
            if (std.mem.eql(u8, grid[i - j], grid[i + j + 1])) {
                eql = true;
                continue;
            }
            return false;
        }
        return eql;
    }

    var eql: bool = false;
    for (0..grid[0].len) |j| {
        if (i + j + 1 >= grid[0].len) break;
        if (i < j) break;

        for (0..grid.len) |k| {
            if (grid[k][i - j] != grid[k][i + j + 1]) {
                return false;
            }
            eql = true;
        }
    }
    return eql;
}

pub fn solve1(input: [][][]const u8) !usize {
    var res: usize = 0;
    outer: for (input) |grid| {
        for (0..grid.len) |i| {
            if (isReflection(grid, false, i)) {
                res += 100 * (i + 1);
                continue :outer;
            }
        }
        for (0..grid[0].len) |i| {
            if (isReflection(grid, true, i)) {
                res += i + 1;
                break;
            }
        }
    }
    return res;
}

pub fn solve2(input: [][][]const u8) !usize {
    var res: usize = 0;
    outer: for (input) |grid| {
        var m = try alloc.alloc([]u8, grid.len);
        for (grid, 0..) |line, i| {
            m[i] = try alloc.alloc(u8, grid[0].len);
            std.mem.copyForwards(u8, m[i], line);
        }
        var x: usize = 0;
        var y: usize = 0;
        var mem_hori = try alloc.alloc(?bool, grid.len);
        var mem_vert = try alloc.alloc(?bool, grid[0].len);
        for (0..grid.len) |i| mem_hori[i] = null;
        for (0..grid[0].len) |i| mem_vert[i] = null;

        while (true) {
            const old = m[x][y];
            if (old == '.') m[x][y] = '#';
            if (old == '#') m[x][y] = '.';
            for (0..grid.len) |i| {
                if (mem_hori[i] == null) mem_hori[i] = isReflection(grid, false, i);
                if (mem_hori[i].?) continue;
                if (isReflection(m, false, i)) {
                    res += 100 * (i + 1);
                    continue :outer;
                }
            }
            for (0..grid[0].len) |i| {
                if (mem_vert[i] == null) mem_vert[i] = isReflection(grid, true, i);
                if (mem_vert[i].?) continue;
                if (isReflection(m, true, i)) {
                    res += i + 1;
                    continue :outer;
                }
            }
            m[x][y] = old;
            if (y < grid[0].len) y += 1;
            if (y == grid[0].len) {
                y = 0;
                x = x + 1;
            }
            if (x == grid.len) unreachable;
        }
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
