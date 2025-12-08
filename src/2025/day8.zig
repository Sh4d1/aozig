const std = @import("std");
const aozig = @import("aozig");

pub var alloc: std.mem.Allocator = std.heap.page_allocator;

const Couple = struct {
    dist: isize,
    p1: usize,
    p2: usize,
};

const CoupleQueueAsc = std.PriorityQueue(Couple, void, struct {
    fn cmp(_: void, a: Couple, b: Couple) std.math.Order {
        return std.math.order(a.dist, b.dist);
    }
}.cmp);

const CoupleQueueDesc = std.PriorityQueue(Couple, void, struct {
    fn cmp(_: void, a: Couple, b: Couple) std.math.Order {
        return std.math.order(b.dist, a.dist);
    }
}.cmp);

const UnionFind = struct {
    parent: []usize,
    size: []usize,

    fn init(allocator: std.mem.Allocator, n: usize) !UnionFind {
        const parent = try allocator.alloc(usize, n);
        const size = try allocator.alloc(usize, n);
        @memset(size, 1);
        for (0..n) |i| parent[i] = i;
        return .{ .parent = parent, .size = size };
    }

    fn find(self: *UnionFind, x: usize) usize {
        if (self.parent[x] != x) {
            self.parent[x] = self.find(self.parent[x]);
        }
        return self.parent[x];
    }

    fn merge(self: *UnionFind, x: usize, y: usize) bool {
        const xf = self.find(x);
        const yf = self.find(y);
        if (xf == yf) return false;

        if (self.size[xf] < self.size[yf]) {
            self.parent[xf] = yf;
            self.size[yf] += self.size[xf];
        } else {
            self.parent[yf] = xf;
            self.size[xf] += self.size[yf];
        }

        return true;
    }
};

const Coord3 = struct {
    x: isize,
    y: isize,
    z: isize,

    fn distSquared(self: Coord3, other: Coord3) isize {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        const dz = self.z - other.z;
        return dx * dx + dy * dy + dz * dz;
    }
};

const T = []Coord3;

pub fn parse(input: []const u8) !T {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var res: std.array_list.Aligned(Coord3, null) = .empty;
    while (lines.next()) |line| {
        var split = std.mem.splitScalar(u8, line, ',');
        try res.append(alloc, .{
            .x = try std.fmt.parseInt(isize, split.next().?, 10),
            .y = try std.fmt.parseInt(isize, split.next().?, 10),
            .z = try std.fmt.parseInt(isize, split.next().?, 10),
        });
    }
    return res.toOwnedSlice(alloc);
}

pub fn solve1(input: T) !usize {
    const connections: usize = if (input.len == 20) 10 else 1000;
    var max_dist: isize = std.math.maxInt(isize);
    var heap = CoupleQueueDesc.init(alloc, {});

    for (input, 0..) |c, i| {
        for (input[i + 1 ..], i + 1..) |cc, j| {
            const dist = c.distSquared(cc);

            if (heap.count() < connections) {
                try heap.add(.{ .dist = dist, .p1 = i, .p2 = j });
                if (heap.count() == connections) {
                    max_dist = heap.peek().?.dist;
                }
            } else if (dist < max_dist) {
                _ = heap.remove();
                try heap.add(.{ .dist = dist, .p1 = i, .p2 = j });
                max_dist = heap.peek().?.dist;
            }
        }
    }

    var uf = try UnionFind.init(alloc, input.len);
    while (heap.removeOrNull()) |couple| {
        _ = uf.merge(couple.p1, couple.p2);
    }

    var max: [3]usize = [3]usize{ 0, 0, 0 };

    for (uf.parent, 0..) |p, i| {
        if (p != i) continue;
        const size = uf.size[i];
        if (size <= max[2]) continue;
        if (size <= max[1]) {
            max[2] = size;
        } else if (size <= max[0]) {
            max[2] = max[1];
            max[1] = size;
        } else {
            max[2] = max[1];
            max[1] = max[0];
            max[0] = size;
        }
    }

    return max[0] * max[1] * max[2];
}

pub fn solve2(input: T) !usize {
    var heap = CoupleQueueAsc.init(alloc, {});
    for (input, 0..) |c, i| {
        for (input[i + 1 ..], i + 1..) |cc, j| {
            const dist = c.distSquared(cc);
            try heap.add(.{ .dist = dist, .p1 = i, .p2 = j });
        }
    }
    var uf = try UnionFind.init(alloc, input.len);

    var last_couple: Couple = undefined;
    var circuits_count: usize = input.len;

    while (heap.removeOrNull()) |couple| {
        if (uf.merge(couple.p1, couple.p2)) {
            circuits_count -= 1;
            last_couple = couple;

            if (circuits_count == 1) break;
        }
    }

    const x1 = input[last_couple.p1].x;
    const x2 = input[last_couple.p2].x;
    return @intCast(x1 * x2);
}

test "example" {
    const input =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;
    const parsed = try parse(input);
    try std.testing.expectEqual(@as(usize, 40), try solve1(parsed));
    try std.testing.expectEqual(@as(usize, 25272), try solve2(parsed));
}
