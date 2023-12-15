const std = @import("std");
pub var alloc = std.heap.page_allocator;

pub fn solve1(input: [][]const u8) !usize {
    var g = try alloc.alloc([]u8, input.len);
    for (0..input.len) |i| {
        g[i] = try alloc.alloc(u8, input[0].len);
        for (0..input[0].len) |j| {
            g[i][j] = input[i][j];
        }
    }
    north(g);
    return load(g);
}

pub fn north(g: [][]u8) void {
    for (1..g.len) |i| {
        for (0..g[0].len) |j| {
            if (g[i][j] == 'O') {
                for (1..i + 1) |_k| {
                    const k = i - _k;
                    if (g[k][j] != '.') break;
                    std.mem.swap(u8, &g[k][j], &g[k + 1][j]);
                }
            }
        }
    }
}

pub fn west(g: [][]u8) void {
    for (1..g[0].len) |j| {
        for (0..g.len) |i| {
            if (g[i][j] == 'O') {
                for (1..j + 1) |_k| {
                    const k = j - _k;
                    if (g[i][k] != '.') break;
                    std.mem.swap(u8, &g[i][k], &g[i][k + 1]);
                }
            }
        }
    }
}

pub fn south(g: [][]u8) void {
    for (1..g.len) |_i| {
        const i = g.len - _i - 1;
        for (0..g[0].len) |j| {
            if (g[i][j] == 'O') {
                for (i + 1..g.len) |k| {
                    if (g[k][j] != '.') break;
                    std.mem.swap(u8, &g[k][j], &g[k - 1][j]);
                }
            }
        }
    }
}

pub fn east(g: [][]u8) void {
    for (1..g[0].len) |_j| {
        const j = g[0].len - _j - 1;
        for (0..g.len) |i| {
            if (g[i][j] == 'O') {
                for (j + 1..g[0].len) |k| {
                    if (g[i][k] != '.') break;
                    std.mem.swap(u8, &g[i][k], &g[i][k - 1]);
                }
            }
        }
    }
}

pub fn cycle(g: [][]u8) void {
    north(g);
    west(g);
    south(g);
    east(g);
}

pub fn load(g: [][]u8) usize {
    var res: usize = 0;
    for (0..g.len) |i| {
        for (0..g[0].len) |j| {
            if (g[i][j] == 'O') res += g.len - i;
        }
    }
    return res;
}
pub fn hash(key: [][]u8) u64 {
    var h = std.hash.Wyhash.init(123);
    for (key) |l| h.update(l);
    return h.final();
}

pub fn solve2(input: [][]const u8) !usize {
    var hm = std.AutoHashMap(usize, usize).init(alloc);
    var g = try alloc.alloc([]u8, input.len);
    for (0..input.len) |i| {
        g[i] = try alloc.alloc(u8, input[0].len);
        for (0..input[0].len) |j| {
            g[i][j] = input[i][j];
        }
    }
    const n = 1000000000;
    var ni: usize = 0;
    while (true) {
        if (hm.get(hash(g))) |v| {
            const rem_cycle = @rem(n - ni, ni - v);
            for (0..rem_cycle) |_| cycle(g);
            return load(g);
        }
        try hm.put(hash(g), ni);
        ni += 1;
        cycle(g);
    }

    unreachable;
}

pub fn parse(input: []const u8) ![][]const u8 {
    var res = std.ArrayList([]const u8).init(alloc);
    var patterns = std.mem.tokenizeScalar(u8, input, '\n');

    while (patterns.next()) |lines| {
        try res.append(lines);
    }
    return try res.toOwnedSlice();
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
