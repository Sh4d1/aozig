const std = @import("std");
const aozig = @import("aozig");
const Range = aozig.range.Range(usize);

pub var alloc: std.mem.Allocator = std.heap.page_allocator;

const Input = struct {
    ranges: []Range,
    available: []usize,
};

const T = Input;

pub fn parse(input: []const u8) !T {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var ranges: std.array_list.Aligned(Range, null) = .empty;
    while (lines.next()) |line| {
        if (line.len == 0) break;
        try ranges.append(alloc, try Range.parse(line, '-'));
    }

    var availables: std.array_list.Aligned(usize, null) = .empty;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try availables.append(alloc, try std.fmt.parseInt(usize, line, 10));
    }

    return .{
        .ranges = try ranges.toOwnedSlice(alloc),
        .available = try availables.toOwnedSlice(alloc),
    };
}

pub fn solve1(input: T) !usize {
    var res: usize = 0;
    for (input.available) |a| {
        for (input.ranges) |r| {
            if (r.contains(a)) {
                res += 1;
                break;
            }
        }
    }
    return res;
}

pub fn solve2(input: T) !u64 {
    const items = input.ranges;
    std.sort.heap(Range, items, void{}, struct {
        fn less(_: void, a: Range, b: Range) bool {
            if (a.start == b.start) return a.end < b.end;
            return a.start < b.start;
        }
    }.less);

    var res: u64 = 0;
    var current = items[0];
    for (items[1..]) |next| {
        if (current.merge(next)) |merged| {
            current = merged;
        } else {
            res += current.len();
            current = next;
        }
    }
    res += current.len();
    return res;
}

test "example" {
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;
    const parsed = try parse(input);
    try std.testing.expectEqual(@as(usize, 3), try solve1(parsed));
    try std.testing.expectEqual(@as(u64, 14), try solve2(parsed));
}
