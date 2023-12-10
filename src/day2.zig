const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Try = struct {
    blue: u32,
    red: u32,
    green: u32,
};

const Game = struct {
    id: u32,
    tries: []Try,
};

pub fn solve1(input: []Game) u32 {
    var res: u32 = 0;
    outer: for (input) |g| {
        for (g.tries) |t| {
            if (t.red > 12 or t.green > 13 or t.blue > 14) {
                continue :outer;
            }
        }
        res += g.id;
    }

    return res;
}

pub fn solve2(input: []Game) u32 {
    var res: u32 = 0;
    for (input) |g| {
        var mr: u32 = 0;
        var mg: u32 = 0;
        var mb: u32 = 0;
        for (g.tries) |t| {
            if (t.red > mr) {
                mr = t.red;
            }
            if (t.blue > mb) {
                mb = t.blue;
            }
            if (t.green > mg) {
                mg = t.green;
            }
        }
        res += mr * mg * mb;
    }

    return res;
}

pub fn parse(input: []const u8) ![]Game {
    var res = std.ArrayList(Game).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var tries_res = std.ArrayList(Try).init(alloc);

        var split = std.mem.tokenizeScalar(u8, line, ':');
        const id = try std.fmt.parseInt(u32, split.next().?[5..], 10);
        var tries = std.mem.tokenizeScalar(u8, split.next().?, ';');
        while (tries.next()) |t| {
            var try_res: Try = .{
                .green = 0,
                .blue = 0,
                .red = 0,
            };

            var cubes = std.mem.tokenizeScalar(u8, t, ',');
            while (cubes.next()) |cube| {
                const trim_cube = std.mem.trim(u8, cube, " ");
                var split_cube = std.mem.tokenizeScalar(u8, trim_cube, ' ');
                const n = try std.fmt.parseInt(u32, split_cube.next().?, 10);
                const color = split_cube.next().?;
                if (std.mem.eql(u8, color, "blue")) {
                    try_res.blue = n;
                }
                if (std.mem.eql(u8, color, "red")) {
                    try_res.red = n;
                }
                if (std.mem.eql(u8, color, "green")) {
                    try_res.green = n;
                }
            }
            try tries_res.append(try_res);
        }

        try res.append(Game{
            .id = id,
            .tries = try tries_res.toOwnedSlice(),
        });
    }
    return res.toOwnedSlice();
}

const test_data =
    \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
    \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
    \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
    \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
    \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
;

test "test-1" {
    const res: u32 = solve1(try parse(test_data));
    try std.testing.expectEqual(res, 8);
}

test "test-2" {
    const res: u32 = solve2(try parse(test_data));
    try std.testing.expectEqual(res, 2286);
}
