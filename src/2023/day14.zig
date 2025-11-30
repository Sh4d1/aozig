const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Input = struct {
    g: []u8,
    n: usize,
};

pub fn solve1(input: Input) !usize {
    var g = try alloc.alloc(u8, input.n * input.n);
    for (0..input.n * input.n) |i| g[i] = input.g[i];
    try north(g, input.n);
    return load(g, input.n);
}

pub fn north(g: []u8, n: usize) !void {
    var stops = try alloc.alloc(usize, n);
    for (0..n) |i| stops[i] = 0;

    var p: usize = 0;
    for (0..n) |i| {
        for (0..n) |j| {
            switch (g[p]) {
                'O' => {
                    g[p] = '.';
                    g[stops[j] * n + j] = 'O';
                    stops[j] += 1;
                },
                '#' => stops[j] = i + 1,
                else => {},
            }
            p += 1;
        }
    }
}

pub fn west(g: []u8, n: usize) !void {
    var start: usize = 0;
    var p: usize = 0;
    for (0..n) |_| {
        var stop: usize = 0;
        for (0..n) |i| {
            switch (g[p]) {
                'O' => {
                    g[p] = '.';
                    g[start + stop] = 'O';
                    stop += 1;
                },
                '#' => stop = i + 1,
                else => {},
            }
            p += 1;
        }
        start += n;
    }
}

pub fn south(g: []u8, n: usize) !void {
    var stops = try alloc.alloc(usize, n);
    for (0..n) |i| stops[i] = n - 1;

    var p: usize = n * n - 1;
    for (0..n) |_i| {
        const i = n - _i - 1;
        for (0..n) |_j| {
            const j = n - _j - 1;
            switch (g[p]) {
                'O' => {
                    g[p] = '.';
                    g[stops[j] * n + j] = 'O';
                    if (stops[j] > 0) stops[j] -= 1;
                },
                '#' => {
                    if (i > 0) stops[j] = i - 1 else {}
                },
                else => {},
            }
            if (p > 0) p -= 1;
        }
    }
}

pub fn east(g: []u8, n: usize) !void {
    var start: usize = n * n - n;
    var p: usize = n * n - 1;
    for (0..n) |_| {
        var stop: usize = n - 1;
        for (0..n) |_j| {
            const j = n - _j - 1;
            switch (g[p]) {
                'O' => {
                    g[p] = '.';
                    g[start + stop] = 'O';
                    if (stop > 0) stop -= 1;
                },
                '#' => if (j > 0) {
                    stop = j - 1;
                },
                else => {},
            }
            if (p > 0) p -= 1;
        }
        if (start >= n) start -= n;
    }
}

pub fn cycle(g: []u8, n: usize) !void {
    try north(g, n);
    try west(g, n);
    try south(g, n);
    try east(g, n);
}

pub fn load(g: []u8, n: usize) usize {
    var res: usize = 0;
    for (0..n) |i| {
        for (0..n) |j| {
            if (g[i * n + j] == 'O') res += n - i;
        }
    }
    return res;
}
pub fn hash(key: []u8) u64 {
    var h = std.hash.XxHash3.init(0);
    h.update(key);
    return h.final();
}

pub fn solve2(input: Input) !usize {
    var mem = try alloc.alloc(?u64, 500);
    for (0..500) |i| mem[i] = null;

    var g = try alloc.alloc(u8, input.n * input.n);
    for (0..input.n * input.n) |i| g[i] = input.g[i];

    const n = 1000000000;
    var ni: usize = 0;
    while (true) {
        const h = hash(g);
        for (mem, 0..) |m, i| {
            if (m == null) break;
            if (m.? == h) {
                const rem_cycle = @rem(n - ni, ni - i);
                for (0..rem_cycle) |_| try cycle(g, input.n);
                return load(g, input.n);
            }
        }
        mem[ni] = h;
        ni += 1;
        try cycle(g, input.n);
    }
    unreachable;
}

pub fn parse(input: []const u8) !Input {
    var res = std.array_list.AlignedManaged(u8, null).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var n: usize = undefined;

    while (lines.next()) |line| {
        n = line.len;
        try res.appendSlice(line);
    }
    return Input{
        .n = n,
        .g = try res.toOwnedSlice(),
    };
}

const test_data =
    \\O....#....
    \\O.OO#....#
    \\.....##...
    \\OO.#O....O
    \\.O.....O#.
    \\O.#..O.#.#
    \\..O..#O..O
    \\.......O..
    \\#....###..
    \\#OO..#....
;

test "test-1" {
    const res: usize = try solve1(try parse(test_data));
    try std.testing.expectEqual(res, 136);
}

test "test-2" {
    const res: usize = try solve2(try parse(test_data));
    try std.testing.expectEqual(res, 64);
}
