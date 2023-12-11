const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Dir = enum {
    N,
    E,
    W,
    S,

    pub fn add(self: Dir, other: Dir) Cell {
        return switch (self) {
            Dir.N => switch (other) {
                Dir.S => Cell.Vert,
                Dir.E => Cell.NE,
                Dir.W => Cell.NW,
                else => unreachable,
            },
            Dir.S => switch (other) {
                Dir.E => Cell.SE,
                Dir.W => Cell.SW,
                else => unreachable,
            },
            Dir.W => Cell.Hori,
            else => unreachable,
        };
    }
};

const Cell = enum {
    Vert,
    Hori,
    NE,
    NW,
    SW,
    SE,
    Ground,
    Start,
};

const Game = struct {
    grid: [][]Cell,
    dir_grid: [][]?Dir,
    start_x: usize,
    start_y: usize,

    pub fn walk(self: *Game) usize {
        var x: usize = self.start_x;
        var y: usize = self.start_y;
        var start_dir: ?Dir = null;
        var start_cell: Cell = undefined;
        if (x > 0) {
            switch (self.grid[x - 1][y]) {
                Cell.Vert, Cell.SW, Cell.SE => {
                    start_dir = Dir.N;
                },
                else => {},
            }
        }
        switch (self.grid[x + 1][y]) {
            Cell.Vert, Cell.NW, Cell.NE => {
                if (start_dir) |d| {
                    start_cell = d.add(Dir.S);
                } else {
                    start_dir = Dir.S;
                }
            },
            else => {},
        }
        if (y > 0) {
            switch (self.grid[x][y - 1]) {
                Cell.Hori, Cell.NE, Cell.SE => {
                    if (start_dir) |d| {
                        start_cell = d.add(Dir.W);
                    } else {
                        start_dir = Dir.W;
                    }
                },
                else => {},
            }
        }
        switch (self.grid[x][y + 1]) {
            Cell.Hori, Cell.NW, Cell.SW => {
                start_cell = start_dir.?.add(Dir.E);
            },
            else => {},
        }

        self.grid[x][y] = start_cell;
        self.dir_grid[x][y] = start_dir.?;

        var dir = start_dir.?;

        var i: usize = 1;
        while (true) {
            const cell = self.grid[x][y];
            switch (cell) {
                Cell.Vert => switch (dir) {
                    Dir.N => x -= 1,
                    Dir.S => x += 1,
                    else => unreachable,
                },
                Cell.Hori => switch (dir) {
                    Dir.W => y -= 1,
                    Dir.E => y += 1,
                    else => unreachable,
                },
                Cell.SW => switch (dir) {
                    Dir.E, Dir.S => {
                        x += 1;
                        dir = Dir.S;
                    },
                    Dir.N, Dir.W => {
                        y -= 1;
                        dir = Dir.W;
                    },
                },
                Cell.SE => switch (dir) {
                    Dir.W, Dir.S => {
                        x += 1;
                        dir = Dir.S;
                    },
                    Dir.N, Dir.E => {
                        y += 1;
                        dir = Dir.E;
                    },
                },
                Cell.NW => switch (dir) {
                    Dir.E, Dir.N => {
                        x -= 1;
                        dir = Dir.N;
                    },
                    Dir.S, Dir.W => {
                        y -= 1;
                        dir = Dir.W;
                    },
                },
                Cell.NE => switch (dir) {
                    Dir.W, Dir.N => {
                        x -= 1;
                        dir = Dir.N;
                    },
                    Dir.S, Dir.E => {
                        y += 1;
                        dir = Dir.E;
                    },
                },
                else => unreachable,
            }
            self.dir_grid[x][y] = dir;
            if (x == self.start_x and y == self.start_y) {
                return i / 2;
            }
            i += 1;
        }
        unreachable;
    }
};

pub fn solve1(input: Game) usize {
    var g: Game = input;
    return g.walk();
}

pub fn solve2(input: Game) usize {
    var g: Game = input;
    _ = g.walk();

    var res: usize = 0;
    for (input.grid, 0..) |l, ii| {
        var last_cross: ?Cell = null;
        var n: usize = 0;
        for (l, 0..) |_, j| {
            if (input.dir_grid[ii][j] != null) {
                switch (input.grid[ii][j]) {
                    Cell.Vert => n += 1,
                    Cell.NE, Cell.NW, Cell.SW, Cell.SE => |c| {
                        // last cross should always be NE, SE or null
                        if (last_cross) |lc| {
                            // here c is always NW or SW
                            if (lc == Cell.NE and c == Cell.SW or lc == Cell.SE and c == Cell.NW) {
                                n += 1;
                            }
                            last_cross = null;
                        } else {
                            last_cross = c;
                        }
                    },
                    else => {},
                }
                continue;
            }
            if (n % 2 == 1) {
                res += 1;
            }
        }
    }
    return res;
}

pub fn parse(input: []const u8) !Game {
    var res = std.ArrayList([]Cell).init(alloc);
    var dir_grid = std.ArrayList([]?Dir).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var start_x: usize = 0;
    var start_y: usize = 0;
    var i: usize = 0;

    while (lines.next()) |l| {
        var line = std.ArrayList(Cell).init(alloc);
        var line_dir = std.ArrayList(?Dir).init(alloc);
        for (l, 0..) |c, j| {
            const cell = switch (c) {
                '|' => Cell.Vert,
                '-' => Cell.Hori,
                'L' => Cell.NE,
                'J' => Cell.NW,
                '7' => Cell.SW,
                'F' => Cell.SE,
                '.' => Cell.Ground,
                'S' => Cell.Start,
                else => unreachable,
            };
            if (cell == Cell.Start) {
                start_x = i;
                start_y = j;
            }
            try line.append(cell);
            try line_dir.append(null);
        }
        i += 1;
        try res.append(try line.toOwnedSlice());
        try dir_grid.append(try line_dir.toOwnedSlice());
    }
    return Game{
        .grid = try res.toOwnedSlice(),
        .dir_grid = try dir_grid.toOwnedSlice(),
        .start_x = start_x,
        .start_y = start_y,
    };
}

const test_data =
    \\..F7.
    \\.FJ|.
    \\SJ.L7
    \\|F--J
    \\LJ...
;

test "test-1" {
    const res: usize = solve1(try parse(test_data));
    try std.testing.expectEqual(res, 8);
}

const test_data_2 =
    \\...........
    \\.S-------7.
    \\.|F-----7|.
    \\.||.....||.
    \\.||.....||.
    \\.|L-7.F-J|.
    \\.|..|.|..|.
    \\.L--J.L--J.
    \\...........
;

test "test-2" {
    const res: usize = solve2(try parse(test_data_2));
    try std.testing.expectEqual(res, 4);
}

const test_data_3 =
    \\.F----7F7F7F7F-7....
    \\.|F--7||||||||FJ....
    \\.||.FJ||||||||L7....
    \\FJL7L7LJLJ||LJ.L-7..
    \\L--J.L7...LJS7F-7L7.
    \\....F-J..F7FJ|L7L7L7
    \\....L7.F7||L7|.L7L7|
    \\.....|FJLJ|FJ|F7|.LJ
    \\....FJL-7.||.||||...
    \\....L---J.LJ.LJLJ...
;

test "test-3" {
    const res: usize = solve2(try parse(test_data_3));
    try std.testing.expectEqual(res, 8);
}

const test_data_4 =
    \\FF7FSF7F7F7F7F7F---7
    \\L|LJ||||||||||||F--J
    \\FL-7LJLJ||||||LJL-77
    \\F--JF--7||LJLJ7F7FJ-
    \\L---JF-JLJ.||-FJLJJ7
    \\|F|F-JF---7F7-L7L|7|
    \\|FFJF7L7F-JF7|JL---7
    \\7-L-JL7||F7|L7F-7F7|
    \\L.L7LFJ|||||FJL7||LJ
    \\L7JLJL-JLJLJL--JLJ.L
;

test "test-4" {
    const res: usize = solve2(try parse(test_data_4));
    try std.testing.expectEqual(res, 10);
}
