const std = @import("std");
pub var alloc = std.heap.page_allocator;

const MemKey = struct {
    usize,
    usize,
    usize,
};

const Row = struct {
    patterns: []const u8,
    list: []usize,

    pub fn solve(self: Row, mem: *std.AutoArrayHashMap(MemKey, usize), pattern_index: usize, list_index: usize, repetition: usize) !usize {
        const mem_key: MemKey = .{ pattern_index, list_index, repetition };
        if (mem.get(mem_key)) |v| return v;

        // the end
        if (self.patterns.len == pattern_index) {
            // we have a way o/
            if (repetition == 0 and self.list.len == list_index) return 1;
            if (self.list.len == list_index + 1 and self.list[list_index] == repetition) return 1;
            // we don't have a way :(
            return 0;
        }

        var res: usize = 0;
        const current_pattern = self.patterns[pattern_index];

        if (current_pattern == '.' or current_pattern == '?') {
            // let's try the next one
            if (repetition == 0) res += try self.solve(mem, pattern_index + 1, list_index, 0);
            // it's a match, we can solve the next pattern
            if (repetition != 0 and list_index < self.list.len and self.list[list_index] == repetition) res += try self.solve(mem, pattern_index + 1, list_index + 1, 0);
        }

        if (current_pattern == '#' or current_pattern == '?') {
            // le'ts continue the repetition
            res += try self.solve(mem, pattern_index + 1, list_index, repetition + 1);
        }

        // happy cpu
        try mem.put(mem_key, res);
        return res;
    }
};

pub fn solve1(input: []Row) !usize {
    var res: usize = 0;
    for (input) |r| {
        var mem = std.AutoArrayHashMap(MemKey, usize).init(alloc);
        defer mem.deinit();
        res += try r.solve(&mem, 0, 0, 0);
    }
    return res;
}
pub fn solve2(input: []Row) !usize {
    var res: usize = 0;
    for (input) |r| {
        var mem = std.AutoArrayHashMap(MemKey, usize).init(alloc);
        defer mem.deinit();
        res += try r.solve(&mem, 0, 0, 0);
    }
    return res;
}

pub fn parse(input: []const u8) ![]Row {
    var res = std.ArrayList(Row).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var list = std.ArrayList(usize).init(alloc);
        var split = std.mem.tokenizeScalar(u8, line, ' ');
        const pattern = split.next().?;
        var list_split = std.mem.tokenizeScalar(u8, split.next().?, ',');
        while (list_split.next()) |p| try list.append(try std.fmt.parseInt(usize, p, 10));
        try res.append(Row{
            .patterns = pattern,
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
        var final_list = std.ArrayList(usize).init(alloc);

        var split = std.mem.tokenizeScalar(u8, line, ' ');
        const pattern = split.next().?;
        var list_split = std.mem.tokenizeScalar(u8, split.next().?, ',');
        while (list_split.next()) |p| try list.append(try std.fmt.parseInt(usize, p, 10));
        const initial_line = try list.toOwnedSlice();
        for (0..5) |i| {
            for (pattern) |p| try patterns.append(p);
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
