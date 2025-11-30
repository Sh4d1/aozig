const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Row = struct {
    patterns: []const u8,
    list: []usize,

    fn key(self: Row, i: usize, j: usize) usize {
        return i * (self.list.len + 1) + j;
    }

    pub fn solve2(self: Row) !usize {
        var m = try alloc.alloc(usize, (self.patterns.len + 1) * (self.list.len + 1));
        for (0..(self.patterns.len + 1) * (self.list.len + 1)) |i| m[i] = 0;
        m[0] = 1;
        for (self.patterns, 0..) |p, i| {
            for (0..@min(i + 1, self.list.len)) |j| {
                const cur = m[self.key(i, j)];
                if (m[self.key(i, j)] == 0) continue;

                if (p == '.' or p == '?') m[self.key(i + 1, j)] += cur;
                if (p == '.') continue;
                if (i + self.list[j] > self.patterns.len) continue;

                const have_dot = for (i..i + self.list[j]) |ii| {
                    if (self.patterns[ii] == '.') break true;
                } else false;
                if (have_dot) continue;

                if (i + self.list[j] == self.patterns.len) {
                    if (j == self.list.len - 1) m[self.key(self.patterns.len, self.list.len)] += cur;
                    continue;
                }

                if (self.patterns[i + self.list[j]] != '#') {
                    if (j == self.list.len - 1) {
                        const have_pound = for (i + self.list[j]..self.patterns.len) |ii| {
                            if (self.patterns[ii] == '#') break true;
                        } else false;
                        if (have_pound) continue;
                        m[self.key(self.patterns.len, self.list.len)] += cur;
                        continue;
                    }
                    m[self.key(i + self.list[j] + 1, j + 1)] += cur;
                }
            }
        }

        return m[self.key(self.patterns.len, self.list.len)];
    }
};

pub fn solve1(input: []Row) !usize {
    var res: usize = 0;
    for (input) |r| {
        res += try r.solve2();
    }
    return res;
}
pub fn solve2(input: []Row) !usize {
    var res: usize = 0;
    for (input) |r| {
        res += try r.solve2();
    }
    return res;
}

pub fn parse(input: []const u8) ![]Row {
    var res = std.array_list.AlignedManaged(Row, null).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var list = std.array_list.AlignedManaged(usize, null).init(alloc);
        var pa = std.array_list.AlignedManaged(u8, null).init(alloc);
        var split = std.mem.tokenizeScalar(u8, line, ' ');
        var lc: ?u8 = null;
        const pattern = split.next().?;
        for (pattern) |c| {
            if (lc != null and lc == '.' and c == '.') continue;
            lc = c;
            try pa.append(c);
        }
        var list_split = std.mem.tokenizeScalar(u8, split.next().?, ',');
        while (list_split.next()) |p| try list.append(try std.fmt.parseInt(usize, p, 10));
        try res.append(Row{
            .patterns = try pa.toOwnedSlice(),
            .list = try list.toOwnedSlice(),
        });
    }
    return res.toOwnedSlice();
}

pub fn parse2(input: []const u8) ![]Row {
    var res = std.array_list.AlignedManaged(Row, null).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var patterns = std.array_list.AlignedManaged(u8, null).init(alloc);
        var list = std.array_list.AlignedManaged(usize, null).init(alloc);
        var pa = std.array_list.AlignedManaged(u8, null).init(alloc);
        var final_list = std.array_list.AlignedManaged(usize, null).init(alloc);

        var split = std.mem.tokenizeScalar(u8, line, ' ');
        const i_pattern = split.next().?;
        var list_split = std.mem.tokenizeScalar(u8, split.next().?, ',');
        while (list_split.next()) |p| try list.append(try std.fmt.parseInt(usize, p, 10));
        var lc: ?u8 = null;
        for (i_pattern) |c| {
            if (lc != null and lc == '.' and c == '.') continue;
            lc = c;
            try pa.append(c);
        }
        const pattern = try pa.toOwnedSlice();

        const initial_line = try list.toOwnedSlice();
        for (0..5) |i| {
            try patterns.appendSlice(pattern);
            try final_list.appendSlice(initial_line);
            if (i != 4) try patterns.append('?');
        }
        try res.append(Row{
            .patterns = try patterns.toOwnedSlice(),
            .list = try final_list.toOwnedSlice(),
        });
    }
    return res.toOwnedSlice();
}

const test_data =
    \\???.### 1,1,3
    \\.??..??...?##. 1,1,3
    \\?#?#?#?#?#?#?#? 1,3,1,6
    \\????.#...#... 4,1,1
    \\????.######..#####. 1,6,5
    \\?###???????? 3,2,1
;

test "test-1" {
    const res: usize = try solve1(try parse(test_data));
    try std.testing.expectEqual(res, 21);
}

test "test-2" {
    const res: usize = try solve2(try parse2(test_data));
    try std.testing.expectEqual(res, 525152);
}
