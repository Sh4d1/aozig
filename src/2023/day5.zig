const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Interval = struct {
    start: usize,
    end: usize,
};

const Map = struct {
    dest: usize,
    src: usize,
    size: usize,

    pub fn get(self: Map, i: usize) usize {
        if (i >= self.src and i <= self.srcEnd()) {
            return self.dest + i - self.src;
        } else {
            return i;
        }
    }

    pub fn srcEnd(self: Map) usize {
        return self.src + self.size;
    }

    pub fn on(self: Map, src: Interval, known: *std.AutoArrayHashMap(Interval, void), unknown: *std.AutoArrayHashMap(Interval, void)) !void {
        const have_start = src.start >= self.src and src.start < self.srcEnd();
        const have_end = src.end >= self.src and src.end < self.srcEnd();

        // completely in
        if (have_start and have_end) {
            try known.put(.{ .start = self.get(src.start), .end = self.get(src.end) }, void{});
            return;
        }
        const after = Interval{ .start = self.srcEnd(), .end = src.end };
        // left side is in
        if (have_start) {
            try unknown.put(after, void{});
            try known.put(.{ .start = self.get(src.start), .end = self.get(self.srcEnd()) }, void{});
            return;
        }
        if (self.src != 0) {
            const before = Interval{ .start = src.start, .end = self.src - 1 };
            // right side is in
            if (have_end) {
                try unknown.put(before, void{});
                try known.put(.{ .start = self.get(self.src), .end = self.get(src.end) }, void{});
                return;
            }
            // big overlap
            if (src.start < self.src and src.end > self.srcEnd()) {
                try unknown.put(before, void{});
                try unknown.put(after, void{});
                try known.put(.{ .start = self.get(self.src), .end = self.get(self.srcEnd()) }, void{});
                return;
            }
        }

        // no overlap
        try unknown.put(src, void{});
    }
};

const Almanac = struct {
    seeds: []usize,
    maps: [][]Map,
};

pub fn solve1(input: Almanac) usize {
    var res: ?usize = null;
    for (input.seeds) |s| {
        var n = s;
        for (input.maps) |map| {
            n = for (map) |m| {
                if (n >= m.src and n <= m.src + m.size) {
                    break m.dest + n - m.src;
                }
            } else n;
        }
        if (res == null) {
            res = n;
        }

        res = @min(res.?, n);
    }

    return res.?;
}

pub fn solve2(input: Almanac) !usize {
    var res: ?usize = null;
    var known = std.AutoArrayHashMap(Interval, void).init(alloc);

    for (input.seeds, 0..) |s, i| {
        if (i % 2 == 0) {
            try known.put(Interval{ .start = s, .end = s + input.seeds[i + 1] }, void{});
        }
    }

    for (input.maps) |map| {
        var unknown = known;
        known = std.AutoArrayHashMap(Interval, void).init(alloc);

        for (map) |m| {
            var new_unknown = std.AutoArrayHashMap(Interval, void).init(alloc);
            for ((try unknown.clone()).keys()) |i| {
                _ = known.swapRemove(i);
                try m.on(i, &known, &new_unknown);
            }
            unknown = new_unknown;
        }
        for (unknown.keys()) |k| {
            try known.put(k, void{});
        }
    }

    for (known.keys()) |k| {
        if (res == null) {
            res = k.start;
        }
        res = @min(res.?, k.start);
    }

    return res.?;
}

pub fn parse(input: []const u8) !Almanac {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var seeds = std.array_list.AlignedManaged(usize, null).init(alloc);
    var seeds_split = std.mem.tokenizeScalar(u8, std.mem.trim(u8, lines.next().?[6..], " "), ' ');
    while (seeds_split.next()) |seed| {
        try seeds.append(try std.fmt.parseInt(usize, seed, 10));
    }

    var maps = std.array_list.AlignedManaged([]Map, null).init(alloc);
    var map = std.array_list.AlignedManaged(Map, null).init(alloc);
    while (lines.next()) |line| {
        if (line[line.len - 1] == ':') {
            if (map.items.len > 0) {
                try maps.append(try map.toOwnedSlice());
                map = std.array_list.AlignedManaged(Map, null).init(alloc);
            }
            continue;
        }
        var split = std.mem.tokenizeScalar(u8, line, ' ');
        try map.append(Map{
            .dest = try std.fmt.parseInt(usize, split.next().?, 10),
            .src = try std.fmt.parseInt(usize, split.next().?, 10),
            .size = try std.fmt.parseInt(usize, split.next().?, 10),
        });
    }
    try maps.append(try map.toOwnedSlice());
    map = std.array_list.AlignedManaged(Map, null).init(alloc);

    return Almanac{
        .seeds = try seeds.toOwnedSlice(),
        .maps = try maps.toOwnedSlice(),
    };
}

const test_data =
    \\seeds: 79 14 55 13
    \\
    \\seed-to-soil map:
    \\50 98 2
    \\52 50 48
    \\
    \\soil-to-fertilizer map:
    \\0 15 37
    \\37 52 2
    \\39 0 15
    \\
    \\fertilizer-to-water map:
    \\49 53 8
    \\0 11 42
    \\42 0 7
    \\57 7 4
    \\
    \\water-to-light map:
    \\88 18 7
    \\18 25 70
    \\
    \\light-to-temperature map:
    \\45 77 23
    \\81 45 19
    \\68 64 13
    \\
    \\temperature-to-humidity map:
    \\0 69 1
    \\1 0 69
    \\
    \\humidity-to-location map:
    \\60 56 37
    \\56 93 4
;

test "test-1" {
    const res: usize = solve1(try parse(test_data));
    try std.testing.expectEqual(res, 35);
}

test "test-2" {
    const res: usize = try solve2(try parse(test_data));
    try std.testing.expectEqual(res, 46);
}
