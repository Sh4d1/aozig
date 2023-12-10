const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Race = struct {
    time: usize,
    dist: usize,

    pub fn run(self: Race, hold_for: usize) usize {
        return hold_for * (self.time - hold_for);
    }

    // we want to solve (with x = start time) x*(self.time-x) > self.dist
    // we got -x^2 +  x * self.time - self.dist > 0
    // easy, x between the 2 roots of the polynom
    // delta = self.time^2 - 4 * (-1) * (-self.dist) = self.time^2 - 4 * self.dist
    // root1 = (-self.time - sqrt(delta)) / (2*-1) = (self.time+sqrt(delta))/2
    // root2 = (-self.time + sqrt(delta)) / (2*-1) = (self.time-sqrt(delta))/2
    pub fn nways(self: Race) usize {
        const delta: f64 = @floatFromInt(self.time * self.time - 4 * self.dist);
        if (delta < 0) {
            return 0;
        }
        if (delta == 0) {
            return 1;
        }
        const root1: f64 = (@as(f64, @floatFromInt(self.time)) + std.math.sqrt(delta)) / 2.0;
        const root2: f64 = (@as(f64, @floatFromInt(self.time)) - std.math.sqrt(delta)) / 2.0;
        const int_root1: i64 = @intFromFloat(std.math.ceil(root1));
        const int_root2: i64 = @intFromFloat(std.math.floor(root2));

        if (root2 < root1) return @intCast(int_root1 - int_root2 - 1);
        // var res: usize = 0;
        // for (1..self.time) |i| {
        //     if (self.run(i) > self.dist) {
        //         res += 1;
        //     }
        // }
        return 0;
    }
};

pub fn solve1(input: []Race) usize {
    var res: usize = 1;
    for (input) |r| {
        res *= r.nways();
    }
    return res;
}

pub fn solve2(input: Race) usize {
    return input.nways();
}

pub fn parse2(input: []const u8) !Race {
    var time: usize = 0;
    var dist: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    for (lines.next().?[5..]) |t| {
        if (t == ' ') {
            continue;
        }
        time *= 10;
        time += t - '0';
    }
    for (lines.next().?[9..]) |t| {
        if (t == ' ') {
            continue;
        }
        dist *= 10;
        dist += t - '0';
    }
    return Race{
        .time = time,
        .dist = dist,
    };
}

pub fn parse(input: []const u8) ![]Race {
    var res = std.ArrayList(Race).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var times = std.mem.tokenizeScalar(u8, std.mem.trim(u8, lines.next().?[5..], " "), ' ');
    var dists = std.mem.tokenizeScalar(u8, std.mem.trim(u8, lines.next().?[9..], " "), ' ');

    while (true) {
        if (times.next()) |t| {
            try res.append(Race{
                .time = try std.fmt.parseInt(usize, t, 10),
                .dist = try std.fmt.parseInt(usize, dists.next().?, 10),
            });
        } else {
            break;
        }
    }

    return res.toOwnedSlice();
}

const test_data =
    \\Time:      7  15   30
    \\Distance:  9  40  200
;

test "test-1" {
    const res: usize = solve1(try parse(test_data));
    try std.testing.expectEqual(res, 288);
}

test "test-2" {
    const res: usize = solve2(try parse2(test_data));
    try std.testing.expectEqual(res, 71503);
}
