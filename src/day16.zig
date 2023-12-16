const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Pos = struct {
    x: usize,
    y: usize,
    dir: DirEnum,
    visited: Dir = Dir.initEmpty(),

    n: usize,

    pub fn idx(self: Pos) usize {
        return self.x * self.n + self.y;
    }

    pub fn advance(self: *Pos) bool {
        switch (self.dir) {
            .left => {
                if (self.y > 0) self.y -= 1 else return false;
            },
            .right => {
                if (self.y < self.n - 1) self.y += 1 else return false;
            },
            .up => {
                if (self.x > 0) self.x -= 1 else return false;
            },
            .down => {
                if (self.x < self.n - 1) self.x += 1 else return false;
            },
        }
        return true;
    }

    pub fn handleMirror(self: *Pos, mirror: u8) void {
        switch (mirror) {
            '/' => {
                switch (self.dir) {
                    .left => self.dir = Down,
                    .right => self.dir = Up,
                    .up => self.dir = Right,
                    .down => self.dir = Left,
                }
            },
            '\\' => {
                switch (self.dir) {
                    .left => self.dir = Up,
                    .right => self.dir = Down,
                    .up => self.dir = Left,
                    .down => self.dir = Right,
                }
            },
            else => unreachable,
        }
    }
    pub fn handleSplitter(self: *Pos, splitter: u8) ?Pos {
        switch (splitter) {
            '-' => {
                switch (self.dir) {
                    .left, .right => return null,
                    .up, .down => {
                        self.dir = Left;
                        return .{ .x = self.x, .y = self.y, .dir = Right, .n = self.n };
                    },
                }
            },
            '|' => {
                switch (self.dir) {
                    .up, .down => return null,
                    .left, .right => {
                        self.dir = Up;
                        return .{ .x = self.x, .y = self.y, .dir = Down, .n = self.n };
                    },
                }
            },
            else => unreachable,
        }
        return null;
    }

    pub fn get(self: *Pos, input: [][]const u8) u8 {
        return input[self.x][self.y];
    }
};

const DirEnum = enum {
    left,
    right,
    up,
    down,
};

const Dir = std.EnumSet(DirEnum);

const Left = DirEnum.left;
const Right = DirEnum.right;
const Up = DirEnum.up;
const Down = DirEnum.down;

pub fn energize(input: [][]const u8, mem: []?Pos, start: Pos) !usize {
    for (0..input.len * input.len) |i| mem[i] = null;

    var res: usize = 0;
    var q = std.ArrayList(Pos).init(alloc);
    try q.append(start);

    while (q.popOrNull()) |_p| {
        var p = _p;

        if (mem[p.idx()]) |*mp| {
            if (mp.visited.contains(p.dir)) continue;
            mp.visited.insert(p.dir);
        } else {
            res += 1;
            mem[p.idx()] = p;
            mem[p.idx()].?.visited.insert(p.dir);
        }

        const cur = p.get(input);
        switch (cur) {
            '.' => {},
            '/', '\\' => |m| p.handleMirror(m),
            '-', '|' => |m| {
                if (p.handleSplitter(m)) |newp| {
                    var pos = newp;
                    if (pos.advance()) try q.append(pos);
                }
            },
            else => unreachable,
        }
        if (p.advance()) try q.append(p);
    }
    return res;
}

pub fn solve1(input: [][]const u8) !usize {
    const mem = try alloc.alloc(?Pos, input.len * input.len);
    return try energize(input, mem, Pos{ .x = 0, .y = 0, .n = input.len, .dir = Right });
}

pub fn solve2(input: [][]const u8) !usize {
    var res: usize = 0;
    const mem = try alloc.alloc(?Pos, input.len * input.len);

    for (0..input.len) |j| {
        res = @max(res, try energize(input, mem, Pos{ .x = 0, .y = j, .n = input.len, .dir = Down }));
        res = @max(res, try energize(input, mem, Pos{ .x = input.len - 1, .y = j, .n = input.len, .dir = Up }));
    }
    for (0..input.len) |i| {
        res = @max(res, try energize(input, mem, Pos{ .x = i, .y = 0, .n = input.len, .dir = Right }));
        res = @max(res, try energize(input, mem, Pos{ .x = i, .y = input.len - 1, .n = input.len, .dir = Left }));
    }
    return res;
}

pub fn parse(input: []const u8) ![][]const u8 {
    var res = std.ArrayList([]const u8).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |l| {
        try res.append(l);
    }
    return try res.toOwnedSlice();
}

const test_data =
    \\.|...\....
    \\|.-.\.....
    \\.....|-...
    \\........|.
    \\..........
    \\.........\
    \\..../.\\..
    \\.-.-/..|..
    \\.|....-|.\
    \\..//.|....
;

test "test-1" {
    const res: usize = try solve1(try parse(test_data));
    try std.testing.expectEqual(res, 46);
}

test "test-2" {
    const res: usize = try solve2(try parse(test_data));
    try std.testing.expectEqual(res, 51);
}
