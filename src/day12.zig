const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Row = struct {
    patterns: []const u8,
    list: []usize,

    pub fn init(self: Row) ![]?usize {
        const size = self.patterns.len * (self.list.len + 1);
        var mem = try alloc.alloc(?usize, size);
        for (0..size) |i| mem[i] = null;
        return mem;
    }

    pub fn solve(self: Row, mem: *[]?usize, pattern_index: usize, list_index: usize) !usize {
        if (pattern_index >= self.patterns.len) return @intFromBool(list_index == self.list.len);

        const mem_key: usize = pattern_index * (self.list.len + 1) + list_index;
        if (mem.*[mem_key]) |v| return v;

        var res: usize = 0;
        const current_pattern = self.patterns[pattern_index];

        if (current_pattern == '.' or current_pattern == '?') res += try self.solve(mem, pattern_index + 1, list_index);

        if (current_pattern == '#' or current_pattern == '?') {
            if (list_index < self.list.len and pattern_index + self.list[list_index] <= self.patterns.len) {
                if (for (pattern_index..pattern_index + self.list[list_index]) |i| {
                    if (self.patterns[i] == '.') break false;
                } else true) {
                    if (pattern_index + self.list[list_index] == self.patterns.len or self.patterns[pattern_index + self.list[list_index]] != '#') {
                        res += try self.solve(mem, pattern_index + self.list[list_index] + 1, list_index + 1);
                    }
                }
            }
        }

        mem.*[mem_key] = res;
        return res;
    }
};

pub fn solve1(input: []Row) !usize {
    var res: usize = 0;
    for (input) |r| {
        var m = try r.init();
        res += try r.solve(&m, 0, 0);
    }
    return res;
}
pub fn solve2(input: []Row) !usize {
    var res: usize = 0;
    for (input) |r| {
        var m = try r.init();
        res += try r.solve(&m, 0, 0);
    }
    return res;
}

pub fn parse(input: []const u8) ![]Row {
    var res = std.ArrayList(Row).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var list = std.ArrayList(usize).init(alloc);
        var pa = std.ArrayList(u8).init(alloc);
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
    var res = std.ArrayList(Row).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var patterns = std.ArrayList(u8).init(alloc);
        var list = std.ArrayList(usize).init(alloc);
        var pa = std.ArrayList(u8).init(alloc);
        var final_list = std.ArrayList(usize).init(alloc);

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
