const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Grid = struct {
    g: []const u8,
    offset: usize,
};

const Pos = struct {
    p: usize,
    dir: DirEnum,
    visited: Dir = Dir.initEmpty(),

    pub fn advance(self: *Pos, g: Grid) bool {
        switch (self.dir) {
            .left => {
                if (@mod(self.p, g.offset) != 0) self.p -= 1 else return false;
            },
            .right => {
                if (@mod(self.p, g.offset) != g.offset - 1) self.p += 1 else return false;
            },
            .up => {
                if (self.p >= g.offset) self.p -= g.offset else return false;
            },
            .down => {
                if (self.p + g.offset < g.g.len) self.p += g.offset else return false;
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
                        return .{ .p = self.p, .dir = Right };
                    },
                }
            },
            '|' => {
                switch (self.dir) {
                    .up, .down => return null,
                    .left, .right => {
                        self.dir = Up;
                        return .{ .p = self.p, .dir = Down };
                    },
                }
            },
            else => unreachable,
        }
        return null;
    }

    pub fn get(self: *Pos, input: Grid) u8 {
        return input.g[self.p];
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

pub fn energize(input: Grid, mem: []?Pos, start: Pos) !usize {
    for (0..input.g.len) |i| mem[i] = null;

    var res: usize = 0;
    var q = std.ArrayList(Pos).init(alloc);
    try q.append(start);

    outer: while (q.popOrNull()) |_p| {
        var p = _p;

        if (mem[p.p]) |*mp| {
            if (mp.visited.contains(p.dir)) continue;
            mp.visited.insert(p.dir);
        } else {
            res += 1;
            mem[p.p] = p;
            mem[p.p].?.visited.insert(p.dir);
        }

        while (p.get(input) == '.') {
            if (!p.advance(input)) continue :outer;

            if (mem[p.p]) |*mp| {
                if (mp.visited.contains(p.dir)) continue :outer;
                mp.visited.insert(p.dir);
            } else {
                res += 1;
                mem[p.p] = p;
                mem[p.p].?.visited.insert(p.dir);
            }
        }

        const cur = p.get(input);
        switch (cur) {
            '/', '\\' => |m| p.handleMirror(m),
            '-', '|' => |m| {
                if (p.handleSplitter(m)) |newp| {
                    var pos = newp;
                    if (pos.advance(input)) try q.append(pos);
                }
            },
            '.' => unreachable,
            else => unreachable,
        }
        if (p.advance(input)) try q.append(p);
    }
    return res;
}

pub fn solve1(input: Grid) !usize {
    const mem = try alloc.alloc(?Pos, input.g.len);
    return try energize(input, mem, Pos{ .p = 0, .dir = Right });
}

pub fn solve2(input: Grid) !usize {
    var res: usize = 0;
    const mem = try alloc.alloc(?Pos, input.g.len);

    for (0..input.offset) |j| {
        res = @max(res, try energize(input, mem, Pos{ .p = j, .dir = Down }));
        res = @max(res, try energize(input, mem, Pos{ .p = input.g.len - 1 - j, .dir = Down }));
        res = @max(res, try energize(input, mem, Pos{ .p = j * input.offset, .dir = Right }));
        res = @max(res, try energize(input, mem, Pos{ .p = j * input.offset - 1, .dir = Right }));
    }
    return res;
}

pub fn parse(input: []const u8) !Grid {
    var res = std.ArrayList(u8).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var offset: usize = undefined;

    while (lines.next()) |l| {
        offset = l.len;
        try res.appendSlice(l);
    }
    return Grid{
        .g = try res.toOwnedSlice(),
        .offset = offset,
    };
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
