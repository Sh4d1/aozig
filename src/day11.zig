const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Cell = enum {
    empty,
    galaxy,
    void,
};

const Point = struct {
    x: usize,
    y: usize,

    fn dist(self: Point, other: Point) usize {
        return @abs(@as(isize, @intCast(other.y)) - @as(isize, @intCast(self.y))) + @abs(@as(isize, @intCast(other.x)) - @as(isize, @intCast(self.x)));
    }
};

pub fn expand(input: [][]Cell, n: usize) ![]Point {
    for (0..input[0].len) |j| {
        if (input[0][j] == Cell.void) continue;

        var empty: bool = true;
        for (0..input.len) |i| {
            if (input[i][j] == Cell.galaxy) empty = false;
        }
        if (empty) {
            for (0..input.len) |i| input[i][j] = Cell.void;
        }
    }

    for (input, 0..) |l, i| {
        if (input[i][0] == Cell.void) continue;
        var empty: bool = true;
        for (l) |c| {
            if (c == Cell.galaxy) empty = false;
        }
        if (empty) {
            for (l, 0..) |_, j| input[i][j] = Cell.void;
        }
    }

    var res = std.ArrayList(Point).init(alloc);
    var delta_x: usize = 0;
    for (input, 0..) |l, i| {
        if (input[i][0] == Cell.void) {
            delta_x += n;
            continue;
        }
        var delta_y: usize = 0;
        for (l, 0..) |c, j| {
            if (c == Cell.void) {
                delta_y += n;
                continue;
            }
            if (c == Cell.galaxy) {
                try res.append(Point{ .x = delta_x + i, .y = delta_y + j });
            }
        }
    }

    return try res.toOwnedSlice();
}

pub fn solve1(input: [][]Cell) !usize {
    var res: usize = 0;
    const points = try expand(input, 1);
    for (points, 0..) |p, i| {
        for (i + 1..points.len) |k| {
            res += p.dist(points[k]);
        }
    }
    return res;
}
pub fn solve2(input: [][]Cell) !usize {
    var res: usize = 0;
    const points = try expand(input, 1000000 - 1);
    for (points, 0..) |p, i| {
        for (i + 1..points.len) |k| {
            res += p.dist(points[k]);
        }
    }
    return res;
}
pub fn parse(input: []const u8) ![][]Cell {
    var res = std.ArrayList([]Cell).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var cell_line = std.ArrayList(Cell).init(alloc);
        for (line) |c| {
            var cell = Cell.empty;
            if (c == '#') {
                cell = Cell.galaxy;
            }
            try cell_line.append(cell);
        }
        try res.append(try cell_line.toOwnedSlice());
    }
    return res.toOwnedSlice();
}

const test_data =
    \\...#......
    \\.......#..
    \\#.........
    \\..........
    \\......#...
    \\.#........
    \\.........#
    \\..........
    \\.......#..
    \\#...#.....
;

test "test-1" {
    const res: usize = try solve1(try parse(test_data));
    try std.testing.expectEqual(res, 374);
}
