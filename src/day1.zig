const std = @import("std");

pub fn solve1(input: [][]const u8) u32 {
    var sum: u32 = 0;
    for (input) |line| {
        var first_digit: ?u32 = null;
        var last_digit: u32 = undefined;
        for (line) |c| {
            if (c > '0' and c <= '9') {
                const digit = c - '0';
                if (first_digit == null) {
                    first_digit = digit;
                }
                last_digit = digit;
            }
        }
        sum += first_digit.? * 10 + last_digit;
    }
    return sum;
}

const digits = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

pub fn solve2(input: [][]const u8) u32 {
    var sum: u32 = 0;
    for (input) |line| {
        var first_digit: ?u32 = null;
        var last_digit: u32 = undefined;
        var i: u32 = 0;
        while (i < line.len) {
            if (line[i] > '0' and line[i] <= '9') {
                const digit = line[i] - '0';
                if (first_digit == null) {
                    first_digit = digit;
                }
                last_digit = digit;
                i += 1;
                continue;
            }
            for (digits, 1..) |d, j| {
                if (i + d.len <= line.len and std.mem.eql(u8, d, line[i .. i + d.len])) {
                    if (first_digit == null) {
                        first_digit = @intCast(j);
                    }
                    last_digit = @intCast(j);
                }
            }
            i += 1;
        }
        sum += first_digit.? * 10 + last_digit;
    }
    return sum;
}

pub fn parse(input: []const u8) ![][]const u8 {
    var res = std.ArrayList([]const u8).init(std.heap.page_allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        try res.append(line);
    }
    return res.toOwnedSlice();
}

const test_data =
    \\1abc2
    \\pqr3stu8vwx
    \\a1b2c3d4e5f
    \\treb7uchet
;

test "test-1" {
    const res: u32 = solve1(try parse(test_data));
    try std.testing.expectEqual(res, 142);
}

const test_data_2 =
    \\two1nine
    \\eightwothree
    \\abcone2threexyz
    \\xtwone3four
    \\4nineeightseven2
    \\zoneight234
    \\7pqrstsixteen
;
test "test-2" {
    const res: u32 = solve2(try parse(test_data_2));
    try std.testing.expectEqual(res, 281);
}
