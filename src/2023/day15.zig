const std = @import("std");
pub var alloc = std.heap.page_allocator;

fn hash(k: []const u8) usize {
    var res: usize = 0;
    for (k) |c| {
        res += c;
        res *= 17;
        res = @rem(res, 256);
    }
    return res;
}

pub fn solve1(input: [][]const u8) !usize {
    var res: usize = 0;
    for (input) |k| {
        const a = hash(k);
        res += a;
    }
    return res;
}

const Entry = struct {
    label: []const u8,
    n: usize,
};

const Box = struct {
    elems: std.array_list.AlignedManaged(Entry, null),
};

pub fn solve2(input: [][]const u8) !usize {
    var boxes = try alloc.alloc(?Box, 256);
    for (0..256) |i| boxes[i] = null;

    for (input) |l| {
        if (std.mem.count(u8, l, "-") != 0) {
            const label = std.mem.trim(u8, l, "-");
            const bn = hash(label);
            if (boxes[bn] == null) continue;
            for (0..boxes[bn].?.elems.items.len) |i| {
                if (std.mem.eql(u8, boxes[bn].?.elems.items[i].label, label)) {
                    _ = boxes[bn].?.elems.orderedRemove(i);
                    break;
                }
            }
        }

        if (std.mem.count(u8, l, "=") != 0) {
            var split = std.mem.tokenizeScalar(u8, l, '=');
            const label = split.next().?;
            const n = try std.fmt.parseInt(usize, split.next().?, 10);
            const bn = hash(label);
            if (boxes[bn]) |b| {
                if (for (0..b.elems.items.len) |ie| {
                    if (std.mem.eql(u8, b.elems.items[ie].label, label)) {
                        b.elems.items[ie].n = n;
                        break false;
                    }
                } else true) {
                    try boxes[bn].?.elems.append(.{ .label = label, .n = n });
                }
            } else {
                boxes[bn] = Box{
                    .elems = std.array_list.AlignedManaged(Entry, null).init(alloc),
                };
                try boxes[bn].?.elems.append(.{ .label = label, .n = n });
            }
        }
    }

    var res: usize = 0;
    for (boxes, 0..) |b, i| {
        if (b == null) continue;
        for (b.?.elems.items, 0..) |c, j| res += (i + 1) * (j + 1) * c.n;
    }
    return res;
}

pub fn parse(input: []const u8) ![][]const u8 {
    var res = std.array_list.AlignedManaged([]const u8, null).init(alloc);
    const line = std.mem.trim(u8, input, "\n");
    var patterns = std.mem.tokenizeScalar(u8, line, ',');

    while (patterns.next()) |l| {
        try res.append(l);
    }
    return try res.toOwnedSlice();
}

const test_data =
    \\rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
;

test "test-1" {
    const res: usize = try solve1(try parse(test_data));
    try std.testing.expectEqual(res, 1320);
}

test "test-2" {
    const res: usize = try solve2(try parse(test_data));
    try std.testing.expectEqual(res, 145);
}
