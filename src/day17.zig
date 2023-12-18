const std = @import("std");
pub var alloc = std.heap.page_allocator;

const State = struct {
    i: usize,
    dir: Dir,
    consecutive: usize,

    fn next(self: State, dir: Dir, grid: Grid) ?struct { State, usize } {
        var i = self.i;
        switch (dir) {
            .left => if (@mod(i, grid.offset) == 0) return null,
            .right => if (@mod(i + 1, grid.offset) == 0) return null,
            .up => if (i <= grid.offset) return null,
            .down => if (i + grid.offset >= grid.g.len) return null,
        }
        switch (dir) {
            .left => i -= 1,
            .right => i += 1,
            .up => i -= grid.offset,
            .down => i += grid.offset,
        }
        return .{ .{ .i = i, .dir = dir, .consecutive = if (dir == self.dir) self.consecutive + 1 else 1 }, grid.g[i] };
    }
};

const Dir = enum {
    left,
    right,
    up,
    down,

    pub fn toIdx(self: Dir) usize {
        return switch (self) {
            .left => 0,
            .right => 1,
            .up => 2,
            .down => 3,
        };
    }

    pub fn turnLeft(self: Dir) Dir {
        return switch (self) {
            .left => Dir.down,
            .down => Dir.right,
            .right => Dir.up,
            .up => Dir.left,
        };
    }
    pub fn turnRight(self: Dir) Dir {
        return switch (self) {
            .left => Dir.up,
            .up => Dir.right,
            .right => Dir.down,
            .down => Dir.left,
        };
    }
};

const DirSet = std.EnumSet(Dir);

const Grid = struct {
    g: []u8,
    offset: usize,
};

fn lessThan(_: void, a: struct { State, usize }, b: struct { State, usize }) std.math.Order {
    return std.math.order(a[1], b[1]);
}

pub fn dijkstra(grid: Grid, min: usize, max: usize) !usize {
    var q = std.PriorityDequeue(
        struct { State, usize },
        void,
        lessThan,
    ).init(alloc, void{});

    try q.add(.{ State{ .i = 0, .dir = Dir.right, .consecutive = 0 }, 0 });
    try q.add(.{ State{ .i = 0, .dir = Dir.down, .consecutive = 0 }, 0 });

    var visited = try alloc.alloc(DirSet, grid.g.len);
    @memset(visited, DirSet.initEmpty());

    var mem = try alloc.alloc(usize, grid.g.len * 4);
    @memset(mem, std.math.maxInt(usize));

    while (q.removeMinOrNull()) |n| {
        const node = n[0];
        const cost = n[1];
        if (node.i == grid.g.len - 1) return cost;
        if (visited[node.i].contains(node.dir)) continue;

        var tmp = node;
        var total_cost: usize = 0;
        for (1..max + 1) |i| {
            if (tmp.next(node.dir, grid)) |nn| {
                total_cost += nn[1];
                if (i >= min) {
                    const idx_left = nn[0].i + grid.g.len * nn[0].dir.turnLeft().toIdx();
                    const idx_right = nn[0].i + grid.g.len * nn[0].dir.turnRight().toIdx();
                    if (total_cost + cost < mem[idx_left]) {
                        mem[idx_left] = total_cost + cost;
                        try q.add(.{ .{ .i = nn[0].i, .dir = nn[0].dir.turnLeft(), .consecutive = 0 }, total_cost + cost });
                    }
                    if (total_cost + cost < mem[idx_right]) {
                        mem[idx_right] = total_cost + cost;
                        try q.add(.{ .{ .i = nn[0].i, .dir = nn[0].dir.turnRight(), .consecutive = 0 }, total_cost + cost });
                    }
                }
                tmp = nn[0];
            } else break;
        }
    }
    unreachable;
}

pub fn solve1(input: Grid) !usize {
    return dijkstra(input, 1, 3);
}

pub fn solve2(input: Grid) !usize {
    return dijkstra(input, 4, 10);
}

pub fn parse(input: []const u8) !Grid {
    var res = std.ArrayList(u8).init(alloc);
    var offset: ?usize = null;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |l| {
        if (offset == null) offset = l.len;
        for (l) |c| {
            try res.append(c - '0');
        }
    }
    return Grid{
        .g = try res.toOwnedSlice(),
        .offset = offset.?,
    };
}

const test_data =
    \\2413432311323
    \\3215453535623
    \\3255245654254
    \\3446585845452
    \\4546657867536
    \\1438598798454
    \\4457876987766
    \\3637877979653
    \\4654967986887
    \\4564679986453
    \\1224686865563
    \\2546548887735
    \\4322674655533
;

test "test-1" {
    const res: usize = try solve1(try parse(test_data));
    try std.testing.expectEqual(res, 102);
}

test "test-2" {
    const res: usize = try solve2(try parse(test_data));
    try std.testing.expectEqual(res, 94);

    const res2: usize = try solve2(try parse(
        \\111111111111
        \\999999999991
        \\999999999991
        \\999999999991
        \\999999999991
    ));
    try std.testing.expectEqual(res2, 71);
}
