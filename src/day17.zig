const std = @import("std");
pub var alloc = std.heap.page_allocator;

const State = struct {
    x: usize,
    y: usize,
    dir: Dir,
    consecutive: usize,

    fn next(self: State, dir: Dir, input: [][]const u8) ?struct { State, usize } {
        var x = self.x;
        var y = self.y;
        switch (dir) {
            .left => if (y == 0) return null,
            .right => if (y >= input[0].len - 1) return null,
            .up => if (x == 0) return null,
            .down => if (x >= input.len - 1) return null,
        }
        switch (dir) {
            .left => y -= 1,
            .right => y += 1,
            .up => x -= 1,
            .down => x += 1,
        }
        return .{ .{ .x = x, .y = y, .dir = dir, .consecutive = if (dir == self.dir) self.consecutive + 1 else 1 }, input[x][y] };
    }
};

const Dir = enum {
    left,
    right,
    up,
    down,

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

const Grid = struct {
    g: [][]const u8,

    pub fn nextp1(self: Grid, s: State) ![]struct { State, usize } {
        var res = std.ArrayList(struct { State, usize }).init(alloc);
        if (s.consecutive < 3) if (s.next(s.dir, self.g)) |ns| try res.append(ns);
        if (s.next(s.dir.turnLeft(), self.g)) |ns| try res.append(ns);
        if (s.next(s.dir.turnRight(), self.g)) |ns| try res.append(ns);
        return res.toOwnedSlice();
    }

    pub fn nextp2(self: Grid, s: State) ![]struct { State, usize } {
        var res = std.ArrayList(struct { State, usize }).init(alloc);
        if (s.consecutive < 10) if (s.next(s.dir, self.g)) |ns| try res.append(ns);
        if (s.consecutive >= 4) {
            if (s.next(s.dir.turnLeft(), self.g)) |ns| try res.append(ns);
            if (s.next(s.dir.turnRight(), self.g)) |ns| try res.append(ns);
        }
        return res.toOwnedSlice();
    }

    pub fn isEnd(self: Grid, s: State) bool {
        return s.x == self.g.len - 1 and s.y == self.g[0].len - 1;
    }

    pub fn isEnd2(self: Grid, s: State) bool {
        return s.x == self.g.len - 1 and s.y == self.g[0].len - 1 and s.consecutive >= 4;
    }
};

fn lessThan(_: void, a: struct { State, usize }, b: struct { State, usize }) std.math.Order {
    return std.math.order(a[1], b[1]);
}

pub fn dijkstra(grid: Grid, next: *const fn (grid: Grid, node: State) std.mem.Allocator.Error![]struct { State, usize }, isEnd: *const fn (grid: Grid, node: State) bool) !usize {
    var q = std.PriorityDequeue(
        struct { State, usize },
        void,
        lessThan,
    ).init(alloc, void{});

    try q.add(.{ State{ .x = 0, .y = 0, .dir = Dir.right, .consecutive = 0 }, 0 });
    try q.add(.{ State{ .x = 0, .y = 0, .dir = Dir.down, .consecutive = 0 }, 0 });

    var mem = std.AutoHashMap(State, usize).init(alloc);

    while (q.removeMinOrNull()) |n| {
        const node = n[0];
        const cost = n[1];
        if (isEnd(grid, node)) return cost;

        for (try next(grid, node)) |nn| {
            if (mem.get(nn[0])) |v| if (nn[1] + cost >= v) continue;
            try mem.put(nn[0], nn[1] + cost);
            try q.add(.{ nn[0], nn[1] + cost });
        }
    }
    unreachable;
}

pub fn solve1(input: [][]const u8) !usize {
    const g = Grid{ .g = input };
    return dijkstra(g, Grid.nextp1, Grid.isEnd);
}

pub fn solve2(input: [][]const u8) !usize {
    const g = Grid{ .g = input };
    return dijkstra(g, Grid.nextp2, Grid.isEnd2);
}

pub fn parse(input: []const u8) ![][]const u8 {
    var res = std.ArrayList([]const u8).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |l| {
        var line = std.ArrayList(u8).init(alloc);
        for (l) |c| {
            try line.append(c - '0');
        }
        try res.append(try line.toOwnedSlice());
    }
    return try res.toOwnedSlice();
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
