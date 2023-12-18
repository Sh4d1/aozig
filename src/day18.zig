const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Dig = struct {
    dir: Dir,
    meters: isize,
};

const Dir = enum {
    left,
    right,
    up,
    down,
};

fn solve(input: []Dig) !usize {
    var x: isize = 0;
    var y: isize = 0;
    var perimeter: isize = 0;
    var points = std.ArrayList(struct { isize, isize }).init(alloc);

    for (input) |d| {
        perimeter += d.meters;
        switch (d.dir) {
            .left => y = y - d.meters,
            .right => y = y + d.meters,
            .up => x = x - d.meters,
            .down => x = x + d.meters,
        }
        try points.append(.{ x, y });
    }
    const p = try points.toOwnedSlice();
    var area: isize = 0;

    // https://en.wikipedia.org/wiki/Shoelace_formula
    // https://fr.wikipedia.org/wiki/Aire_d%27un_polygone
    for (0..p.len - 1) |i| {
        area += p[i][0] * p[i + 1][1] - p[i + 1][0] * p[i][1];
    }
    area = @divTrunc(area, 2);
    if (area < 0) area = -area;

    // https://en.wikipedia.org/wiki/Pick%27s_theorem
    // A = X + perimeter/2 - 1
    // X = A - perimeter/2 + 1
    // we want X + perimeter, so res = A + perimeter/2 + 1
    return @intCast(area + @divTrunc(perimeter, 2) + 1);
}

pub fn solve1(input: []Dig) !usize {
    return solve(input);
}

pub fn solve2(input: []Dig) !usize {
    return solve(input);
}

pub fn parse(input: []const u8) ![]Dig {
    var res = std.ArrayList(Dig).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |l| {
        var split = std.mem.tokenizeScalar(u8, l, ' ');
        const dir = switch (split.next().?[0]) {
            'L' => Dir.left,
            'R' => Dir.right,
            'U' => Dir.up,
            'D' => Dir.down,
            else => unreachable,
        };
        const m = try std.fmt.parseInt(isize, split.next().?, 10);

        try res.append(Dig{ .dir = dir, .meters = m });
    }
    return try res.toOwnedSlice();
}

pub fn parse2(input: []const u8) ![]Dig {
    var res = std.ArrayList(Dig).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |l| {
        var split = std.mem.tokenizeScalar(u8, l, ' ');
        _ = split.next();
        _ = split.next();
        const third = split.next().?;
        const hexa = third[2..7];
        const d = third[7];

        const m = try std.fmt.parseInt(isize, hexa, 16);
        const dir = switch (d) {
            '0' => Dir.right,
            '1' => Dir.down,
            '2' => Dir.left,
            '3' => Dir.up,
            else => unreachable,
        };

        try res.append(Dig{ .dir = dir, .meters = m });
    }
    return try res.toOwnedSlice();
}
const test_data =
    \\R 6 (#70c710)
    \\D 5 (#0dc571)
    \\L 2 (#5713f0)
    \\D 2 (#d2c081)
    \\R 2 (#59c680)
    \\D 2 (#411b91)
    \\L 5 (#8ceee2)
    \\U 2 (#caa173)
    \\L 1 (#1b58a2)
    \\U 2 (#caa171)
    \\R 2 (#7807d2)
    \\U 3 (#a77fa3)
    \\L 2 (#015232)
    \\U 2 (#7a21e3)
;

test "test-1" {
    const res: usize = try solve1(try parse(test_data));
    try std.testing.expectEqual(res, 62);
}

test "test-2" {
    const res: usize = try solve2(try parse2(test_data));
    try std.testing.expectEqual(res, 952408144115);
}
