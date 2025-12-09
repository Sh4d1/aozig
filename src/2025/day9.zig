const std = @import("std");
const aozig = @import("aozig");

pub var alloc: std.mem.Allocator = std.heap.page_allocator;

const Coord = struct {
    x: isize,
    y: isize,

    fn parse(line: []const u8) !Coord {
        var parts = std.mem.tokenizeScalar(u8, line, ',');
        const x = try std.fmt.parseInt(isize, parts.next().?, 10);
        const y = try std.fmt.parseInt(isize, parts.next().?, 10);
        return Coord{ .x = x, .y = y };
    }

    fn area(self: Coord, other: Coord) usize {
        const width = @max(self.x, other.x) - @min(self.x, other.x) + 1;
        const height = @max(self.y, other.y) - @min(self.y, other.y) + 1;
        return @intCast(width * height);
    }
};

const T = []Coord;

pub fn parse(input: []const u8) !T {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var res: std.array_list.Aligned(Coord, null) = .empty;

    while (lines.next()) |line| {
        try res.append(alloc, try Coord.parse(line));
    }
    return res.toOwnedSlice(alloc);
}

pub fn solve1(input: T) !usize {
    var res: usize = 0;
    for (input, 0..) |c1, i| {
        for (input[i + 1 ..]) |c2| {
            const a = c1.area(c2);
            if (a > res) res = a;
        }
    }
    return res;
}

fn isValid(c1: Coord, c2: Coord, points: []const Coord) bool {
    const min_x = @min(c1.x, c2.x);
    const max_x = @max(c1.x, c2.x);
    const min_y = @min(c1.y, c2.y);
    const max_y = @max(c1.y, c2.y);

    for (0..points.len) |i| {
        const curr = points[i];
        const next = points[(i + 1) % points.len];

        if (curr.x == next.x) {
            if (curr.x > min_x and curr.x < max_x) {
                const y1 = @min(curr.y, next.y);
                const y2 = @max(curr.y, next.y);
                if (y1 < max_y and y2 > min_y) return false;
            }
        } else {
            if (curr.y > min_y and curr.y < max_y) {
                const x1 = @min(curr.x, next.x);
                const x2 = @max(curr.x, next.x);
                if (x1 < max_x and x2 > min_x) return false;
            }
        }
    }
    return true;
}

pub fn solve2(input: T) !usize {
    var res: usize = 0;
    for (input, 0..) |c1, i| {
        for (input[i + 1 ..]) |c2| {
            const a = c1.area(c2);
            if (a <= res) continue;
            if (isValid(c1, c2, input)) res = a;
        }
    }
    return res;
}

test "example" {
    const input =
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    ;
    const parsed = try parse(input);
    try std.testing.expectEqual(@as(usize, 50), try solve1(parsed));
    try std.testing.expectEqual(@as(usize, 24), try solve2(parsed));
}
