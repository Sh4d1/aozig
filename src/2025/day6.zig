const std = @import("std");
const aozig = @import("aozig");

pub var alloc: std.mem.Allocator = std.heap.page_allocator;

const Ops = enum { Plus, Times };

const Elem = union(enum) {
    ops: Ops,
    value: usize,

    const Tag = std.meta.Tag(Elem);

    fn parse(input: []const u8) !Elem {
        if (input[0] == '*' or input[0] == '+') {
            return Elem{
                .ops = if (input[0] == '+') .Plus else .Times,
            };
        } else {
            return Elem{
                .value = try std.fmt.parseInt(usize, input, 10),
            };
        }
    }
};

const T = [][]Elem;

pub fn parse(input: []const u8) !T {
    var res: std.array_list.Aligned([]Elem, null) = .empty;
    var lines = std.mem.tokenizeAny(u8, input, "\n");
    while (lines.next()) |line| {
        var parsed_line: std.array_list.Aligned(Elem, null) = .empty;
        var split = std.mem.tokenizeAny(u8, line, " ");
        while (split.next()) |v| {
            try parsed_line.append(alloc, try Elem.parse(v));
        }
        try res.append(alloc, try parsed_line.toOwnedSlice(alloc));
    }
    return try res.toOwnedSlice(alloc);
}

pub fn solve1(input: T) !usize {
    const height = input.len;
    var res: usize = 0;

    const ops = input[height - 1];

    var i: usize = 0;
    while (i < ops.len) : (i += 1) {
        const op = ops[i];
        switch (op.ops) {
            .Plus => {
                for (input[0 .. height - 1]) |line| res += line[i].value;
            },
            .Times => {
                var tmp: usize = 1;
                for (input[0 .. height - 1]) |line| tmp *= line[i].value;
                res += tmp;
            },
        }
    }

    return res;
}

const T2 = [][]const u8;

pub fn parse2(input: []const u8) !T2 {
    var it = std.mem.splitScalar(u8, input, '\n');
    var rows: std.array_list.Aligned([]const u8, null) = .empty;
    while (it.next()) |line| {
        if (line.len == 0) continue;
        try rows.append(alloc, line);
    }

    return try rows.toOwnedSlice(alloc);
}

pub fn solve2(input: T2) !usize {
    var res: usize = 0;

    const ops_line = input[input.len - 1];

    var width: usize = 0;
    for (input) |line| {
        width = @max(width, line.len);
    }

    var values: std.array_list.Aligned(usize, null) = .empty;

    var col = width;
    while (col > 0) {
        col -= 1;
        var value: usize = 0;
        var has_digit = false;
        for (input[0 .. input.len - 1]) |line| {
            if (col >= line.len) continue;
            const c = line[col];
            if (std.ascii.isDigit(c)) {
                has_digit = true;
                value = value * 10 + @as(usize, c - '0');
            }
        }
        if (has_digit) {
            try values.append(alloc, value);
        }

        if (col < ops_line.len and ops_line[col] != ' ') {
            switch (ops_line[col]) {
                '+' => {
                    for (values.items) |v| res += v;
                },
                '*' => {
                    var tmp: usize = 1;
                    for (values.items) |v| tmp *= v;
                    res += tmp;
                },
                else => unreachable,
            }
            values.clearRetainingCapacity();
        }
    }

    return res;
}

test "example" {
    const input =
        \\123 328  51 64
        \\ 45 64  387 23
        \\  6 98  215 314
        \\*   +   *   +
    ;
    const parsed = try parse(input);
    const parsed2 = try parse2(input);
    try std.testing.expectEqual(@as(usize, 4277556), try solve1(parsed));
    try std.testing.expectEqual(@as(usize, 3263827), try solve2(parsed2));
}
