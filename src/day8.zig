const std = @import("std");
const data = @embedFile("day8.txt");
const alloc = std.heap.page_allocator;

const Dir = enum {
    Left,
    Right,
};

const Node = struct {
    cur: []const u8,
    left: []const u8,
    right: []const u8,
};

const Game = struct {
    inst: []Dir,
    nodes: std.StringHashMap(Node),

    pub fn solve(self: Game, start: []const u8, end: []const u8) usize {
        var i: usize = 0;
        var current: []const u8 = start;

        while (true) {
            switch (self.inst[i % self.inst.len]) {
                Dir.Left => current = self.nodes.get(current).?.left,
                Dir.Right => current = self.nodes.get(current).?.right,
            }

            i += 1;
            if (std.mem.eql(u8, current, end) or end.len == 1 and current[2] == end[0]) {
                break;
            }
        }
        return i;
    }
};

pub fn solve1(input: Game) usize {
    return input.solve("AAA", "ZZZ");
}

pub fn solve2(input: Game) usize {
    var iter = input.nodes.keyIterator();
    var res: usize = 1;

    while (iter.next()) |k| {
        if (k.*[2] == 'A') {
            const tmp = input.solve(k.*, "Z");
            res = res * tmp / std.math.gcd(res, tmp);
        }
    }
    return res;
}

pub fn parse(input: []const u8) !Game {
    var res = std.ArrayList(Dir).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    for (lines.next().?) |c| {
        if (c == 'L') {
            try res.append(Dir.Left);
        } else if (c == 'R') {
            try res.append(Dir.Right);
        } else {
            unreachable;
        }
    }

    var nodes = std.StringHashMap(Node).init(alloc);
    while (lines.next()) |l| {
        var split = std.mem.tokenizeScalar(u8, l, '=');
        const cur = std.mem.trim(u8, split.next().?, " ");
        var right = std.mem.tokenizeScalar(u8, std.mem.trim(u8, split.next().?, " ()"), ',');

        try nodes.put(cur, Node{
            .cur = cur,
            .left = right.next().?,
            .right = std.mem.trim(u8, right.next().?, " "),
        });
    }

    return Game{
        .inst = try res.toOwnedSlice(),
        .nodes = nodes,
    };
}

pub fn main() !void {
    const input = try parse(data);
    const input2 = try parse(data);
    std.debug.print("Part1: {}\n", .{solve1(input)});
    std.debug.print("Part2: {}\n", .{solve2(input2)});
}

const test_data =
    \\LLR
    \\
    \\AAA = (BBB, BBB)
    \\BBB = (AAA, ZZZ)
    \\ZZZ = (ZZZ, ZZZ)
;

test "test-1" {
    const res: usize = solve1(try parse(test_data));
    try std.testing.expectEqual(res, 6);
}

test "test-2" {
    const res: usize = solve2(try parse(test_data));
    try std.testing.expectEqual(res, 6);
}
