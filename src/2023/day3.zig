const std = @import("std");
pub var alloc = std.heap.page_allocator;

const CellEnum = enum {
    symbol,
    number,
    empty,
};

const Cell = union(CellEnum) {
    symbol: u8,
    number: *u32,
    empty: void,
};

pub fn has_symbols_around(input: [][]Cell, i: usize, j: usize) bool {
    for (0..3) |ix| {
        for (0..3) |jx| {
            if (i + ix < 1 or i + ix > input.len or j + jx < 1 or j + jx > input[0].len) {
                continue;
            }
            if (input[i + ix - 1][j + jx - 1] == CellEnum.symbol) {
                return true;
            }
        }
    }
    return false;
}

pub fn get_gear_ratio(input: [][]Cell, i: usize, j: usize) u32 {
    var found: u32 = 0;
    var ratio: u32 = 1;
    var current_n: *u32 = &found;
    for (0..3) |ix| {
        for (0..3) |jx| {
            if (i + ix < 1 or i + ix > input.len or j + jx < 1 or j + jx > input[0].len) {
                continue;
            }
            const c: Cell = input[i + ix - 1][j + jx - 1];
            if (c == CellEnum.number and current_n != c.number) {
                found += 1;
                ratio *= c.number.*;
                current_n = c.number;
            }
        }
    }
    if (found == 2) {
        return ratio;
    }
    return 0;
}
pub fn solve1(input: [][]Cell) u32 {
    var res: u32 = 0;
    var is_current_number: bool = false;
    for (input, 0..) |line, i| {
        for (line, 0..) |c, j| {
            switch (c) {
                CellEnum.symbol, CellEnum.empty => is_current_number = false,
                CellEnum.number => |n| if (!is_current_number and has_symbols_around(input, i, j)) {
                    res += n.*;
                    is_current_number = true;
                },
            }
        }
    }
    return res;
}

pub fn solve2(input: [][]Cell) u32 {
    var res: u32 = 0;
    for (input, 0..) |line, i| {
        for (line, 0..) |c, j| {
            switch (c) {
                CellEnum.number, CellEnum.empty => {},
                CellEnum.symbol => |s| if (s == '*') {
                    const ratio: u32 = get_gear_ratio(input, i, j);
                    if (ratio != 0) {
                        res += ratio;
                    }
                },
            }
        }
    }
    return res;
}

pub fn parse(input: []const u8) ![][]Cell {
    var res = std.array_list.AlignedManaged([]Cell, null).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var cell_line = std.array_list.AlignedManaged(Cell, null).init(alloc);
        for (line, 0..) |c, i| {
            var cell = Cell{ .empty = void{} };
            if (c >= '0' and c <= '9') {
                const value: u32 = c - '0';
                if (i == 0 or cell_line.getLast() != CellEnum.number) {
                    const n: *u32 = try alloc.create(u32);
                    n.* = value;
                    cell = Cell{ .number = n };
                } else {
                    cell_line.getLast().number.* *= 10;
                    cell_line.getLast().number.* += value;
                    cell = Cell{ .number = cell_line.getLast().number };
                }
            } else if (c != '.') {
                cell = Cell{ .symbol = c };
            }
            try cell_line.append(cell);
        }
        try res.append(try cell_line.toOwnedSlice());
    }
    return res.toOwnedSlice();
}

const test_data =
    \\467..114..
    \\...*......
    \\..35..633.
    \\......#...
    \\617*......
    \\.....+.58.
    \\..592.....
    \\......755.
    \\...$.*....
    \\.664.598..
;

test "test-1" {
    const res: u32 = solve1(try parse(test_data));
    try std.testing.expectEqual(res, 4361);
}

test "test-2" {
    const res: u32 = solve2(try parse(test_data));
    try std.testing.expectEqual(res, 467835);
}
