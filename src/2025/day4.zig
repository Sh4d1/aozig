const std = @import("std");
const aozig = @import("aozig");
const Grid = aozig.grid.Grid;
const Coord = aozig.grid.Coord;
const Fifo = aozig.fifo.Fifo;

pub var alloc: std.mem.Allocator = std.heap.page_allocator;

pub fn parse(input: []const u8) !Grid(u8) {
    return aozig.grid.parseByteGrid(alloc, input);
}

pub fn solve1(grid: Grid(u8)) usize {
    var res: usize = 0;
    var grid_iter = grid.iter();

    while (grid_iter.next()) |c| {
        if (c.value != '@') continue;
        if (grid.countAdjacentCoord(c.coord, '@') < 4) res += 1;
    }
    return res;
}

pub fn solve2(input: Grid(u8)) !usize {
    var grid = input;
    var neighbor_counts = try grid.newFrom(u8, alloc);
    defer neighbor_counts.deinit(alloc);

    var queue = Fifo(Coord).init(alloc);
    defer queue.deinit();

    var grid_iter = grid.iter();
    while (grid_iter.next()) |c| {
        if (c.value == '@') {
            const count = grid.countAdjacentCoord(c.coord, '@');
            neighbor_counts.setCoord(c.coord, count);
            if (count < 4) {
                try queue.push(c.coord);
            }
        } else {
            neighbor_counts.setCoord(c.coord, 0);
        }
    }

    var res: usize = 0;
    while (queue.pop()) |coord| {
        if (grid.getCoord(coord) != '@') continue;
        if (neighbor_counts.getCoord(coord) >= 4) continue;

        res += 1;
        grid.setCoord(coord, '.');

        var neighbors_iter = grid.neighborIter(coord);
        while (neighbors_iter.next()) |neighbor_coord| {
            if (grid.getCoord(neighbor_coord) == '@') {
                const prev = neighbor_counts.getCoord(neighbor_coord);
                if (prev > 0) {
                    const new_count = prev - 1;
                    neighbor_counts.setCoord(neighbor_coord, new_count);
                    if (new_count <= 3) {
                        try queue.push(neighbor_coord);
                    }
                }
            }
        }
    }

    return res;
}

test "example" {
    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;
    const parsed = try parse(input);
    try std.testing.expectEqual(@as(usize, 13), solve1(parsed));
    try std.testing.expectEqual(@as(usize, 43), try solve2(parsed));
}
