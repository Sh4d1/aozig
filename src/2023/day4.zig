const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Card = struct {
    n: u32,
    copies: u32,
    winning: std.AutoHashMap(u32, void),
    numbers: []u32,
};

pub fn solve1(input: []Card) u32 {
    var res: u32 = 0;
    for (input) |c| {
        var score: u32 = 0;
        for (c.numbers) |n| {
            if (c.winning.get(n)) |_| {
                if (score == 0) {
                    score = 1;
                } else {
                    score *= 2;
                }
            }
        }
        res += score;
    }
    return res;
}

pub fn solve2(input: []Card) u32 {
    var res: u32 = 0;
    for (input, 0..) |c, i| {
        var matches: u32 = 0;
        for (c.numbers) |n| {
            if (c.winning.get(n)) |_| {
                matches += 1;
            }
        }

        for (0..matches) |j| {
            if (i + j + 1 < input.len) {
                input[i + j + 1].copies += c.copies;
            }
        }
        res += c.copies;
    }

    return res;
}

pub fn parse(input: []const u8) ![]Card {
    var res = std.array_list.AlignedManaged(Card, null).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var split_line = std.mem.tokenizeScalar(u8, line, ':');
        const n: u32 = try std.fmt.parseInt(u32, std.mem.trim(u8, split_line.next().?[5..], " "), 10);
        var numbers = std.mem.tokenizeScalar(u8, split_line.next().?, '|');

        var winning = std.mem.tokenizeScalar(u8, std.mem.trim(u8, numbers.next().?, " "), ' ');
        var my_numbers = std.mem.tokenizeScalar(u8, std.mem.trim(u8, numbers.next().?, " "), ' ');

        var winnig_list = std.AutoHashMap(u32, void).init(alloc);
        while (winning.next()) |w| {
            try winnig_list.put(try std.fmt.parseInt(u32, w, 10), void{});
        }

        var my_numbers_list = std.array_list.AlignedManaged(u32, null).init(alloc);
        while (my_numbers.next()) |mn| {
            try my_numbers_list.append(try std.fmt.parseInt(u32, mn, 10));
        }

        try res.append(Card{
            .n = n,
            .copies = 1,
            .winning = winnig_list,
            .numbers = try my_numbers_list.toOwnedSlice(),
        });
    }
    return res.toOwnedSlice();
}

const test_data =
    \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
    \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
    \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
    \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
    \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
    \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
;

test "test-1" {
    const res: u32 = solve1(try parse(test_data));
    try std.testing.expectEqual(res, 13);
}

test "test-2" {
    const res: u32 = solve2(try parse(test_data));
    try std.testing.expectEqual(res, 30);
}
