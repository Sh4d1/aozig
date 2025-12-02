const std = @import("std");
const aozig = @import("aozig");

pub var alloc: std.mem.Allocator = std.heap.page_allocator;

const Direction = enum {
    Left,
    Right,
};

const Rotation = struct {
    direction: Direction,
    distance: isize,
};

const Dial = struct {
    position: isize = 50,

    fn rotate(self: *Dial, rotation: *const Rotation) isize {
        const distance = @mod(rotation.distance, 100);
        var res = @divFloor(rotation.distance, 100);
        switch (rotation.direction) {
            .Left => {
                if (self.position != 0 and self.position < distance) res += 1;
                self.position = @mod(self.position - distance, 100);
            },
            .Right => {
                if (100 - self.position < distance) res += 1;
                self.position = @mod(self.position + distance, 100);
            },
        }
        return res;
    }
};

pub fn parse(input: []const u8) ![]Rotation {
    var lines = std.mem.splitAny(u8, input, "\n");
    var rotations: std.array_list.Aligned(Rotation, null) = .empty;
    defer rotations.deinit(alloc);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        switch (line[0]) {
            'L' => try rotations.append(alloc, Rotation{ .direction = Direction.Left, .distance = try std.fmt.parseInt(isize, line[1..], 10) }),
            'R' => try rotations.append(alloc, Rotation{ .direction = Direction.Right, .distance = try std.fmt.parseInt(isize, line[1..], 10) }),
            else => return error.InvalidInput,
        }
    }
    return rotations.toOwnedSlice(alloc);
}

pub fn solve1(rotations: []Rotation) usize {
    var dial = Dial{};
    var res: usize = 0;

    for (rotations) |rotation| {
        _ = dial.rotate(&rotation);
        if (dial.position == 0) {
            res += 1;
        }
    }
    return res;
}

pub fn solve2(rotations: []Rotation) isize {
    var dial = Dial{};
    var res: isize = 0;

    for (rotations) |rotation| {
        res += dial.rotate(&rotation);
        if (dial.position == 0) {
            res += 1;
        }
    }
    return res;
}

test "example" {
    {
        const input =
            \\L68
            \\L30
            \\R48
            \\L5
            \\R60
            \\L55
            \\L1
            \\L99
            \\R14
            \\L82
        ;
        const res = try parse(input);
        try std.testing.expectEqual(@as(usize, 3), solve1(res));
        try std.testing.expectEqual(@as(isize, 6), solve2(res));
    }
}
