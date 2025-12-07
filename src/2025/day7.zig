const std = @import("std");
const aozig = @import("aozig");
const Grid = aozig.grid.Grid(u8);
const Coord = aozig.grid.Coord;

pub var alloc: std.mem.Allocator = std.heap.page_allocator;

const Parsed = struct {
    grid: Grid,
    start: Coord,
};

const T = Parsed;

pub fn parse(input: []const u8) !T {
    var start: Coord = undefined;
    const Converter = struct {
        var start_ptr: *Coord = undefined;
        fn convert(row: usize, col: usize, ch: u8) u8 {
            if (ch == 'S') start_ptr.* = .{ .row = row, .col = col };
            return ch;
        }
    };
    Converter.start_ptr = &start;
    return .{ .grid = try Grid.parse(alloc, input, Converter.convert), .start = start };
}

pub fn solve1(input: T) !usize {
    var res: usize = 0;
    const grid = input.grid;
    var beams: std.array_list.Aligned(Coord, null) = .empty;

    var visited = try grid.newFrom(bool, alloc);
    @memset(visited.data, false);

    try beams.append(alloc, .{ .row = input.start.row + 1, .col = input.start.col });

    while (beams.pop()) |coord| {
        if (coord.row >= grid.height or coord.col >= grid.width) continue;
        if (visited.getCoord(coord)) continue;

        visited.setCoord(coord, true);

        if (grid.getCoord(coord) == '^') {
            res += 1;
            try beams.append(alloc, .{ .row = coord.row + 1, .col = coord.col - 1 });
            try beams.append(alloc, .{ .row = coord.row + 1, .col = coord.col + 1 });
        } else {
            try beams.append(alloc, .{ .row = coord.row + 1, .col = coord.col });
        }
    }

    return res;
}

pub fn solve2(input: T) !usize {
    var res: usize = 0;
    const grid = input.grid;
    const width = grid.width;
    const height = grid.height;

    var curr = try alloc.alloc(u64, width);
    @memset(curr, 0);
    curr[input.start.col] = 1;

    var next = try alloc.alloc(u64, width);

    var row = input.start.row + 1;
    while (row < height) : (row += 1) {
        @memset(next, 0);
        const below_row = row + 1;

        for (0..width) |col| {
            const count = curr[col];
            if (count == 0) continue;

            if (grid.get(row, col) == '^') {
                if (below_row >= height) {
                    res += count * 2;
                } else {
                    if (col > 0) next[col - 1] += count;
                    if (col + 1 < width) next[col + 1] += count;
                }
            } else {
                if (below_row >= height) {
                    res += count;
                } else {
                    next[col] += count;
                }
            }
        }

        const tmp = curr;
        curr = next;
        next = tmp;
    }

    return res;
}

test "example" {
    const input =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    ;
    const parsed = try parse(input);
    try std.testing.expectEqual(@as(usize, 21), try solve1(parsed));
    try std.testing.expectEqual(@as(usize, 40), try solve2(parsed));
}
