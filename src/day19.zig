const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Game = struct {
    rules: []Rule,
    entries: []Entry,
};

const Rule = struct {
    name: []const u8,

    conds: []Cond,
};

const Cond = struct {
    elem: ?u8 = null,
    cmp: ?u8 = null,
    val: ?usize = null,
    go: []const u8,
};

const C = struct {
    elem: u8,
    cmp: u8,
    val: usize,
};

const Entry = struct {
    x: usize,
    m: usize,
    a: usize,
    s: usize,

    pub fn get(self: Entry, elem: u8) usize {
        return switch (elem) {
            'x' => self.x,
            'm' => self.m,
            'a' => self.a,
            's' => self.s,
            else => unreachable,
        };
    }
};

pub fn solve1(input: Game) !usize {
    var res: usize = 0;
    var hm = std.StringHashMap(Rule).init(alloc);
    for (input.rules) |r| {
        try hm.put(r.name, r);
    }

    for (input.entries) |e| {
        var cur = hm.get("in").?;
        outer: while (true) {
            for (cur.conds) |cond| {
                if (cond.elem != null) {
                    if (cond.cmp.? == '<') {
                        if (e.get(cond.elem.?) >= cond.val.?) {
                            continue;
                        }
                    } else {
                        if (e.get(cond.elem.?) <= cond.val.?) {
                            continue;
                        }
                    }
                }

                if (cond.go[0] == 'R') break :outer;
                if (cond.go[0] == 'A') {
                    res += e.x + e.m + e.a + e.s;
                    break :outer;
                }

                cur = hm.get(cond.go).?;
                continue :outer;
            }
            unreachable;
        }
    }

    return res;
}

pub fn solve2(input: Game) !usize {
    var hm = std.StringHashMap(Rule).init(alloc);
    for (input.rules) |r| {
        try hm.put(r.name, r);
    }

    var final = std.ArrayList([]C).init(alloc);
    const conds = std.ArrayList(C).init(alloc);

    var tmp = std.ArrayList(struct { Rule, std.ArrayList(C) }).init(alloc);
    try tmp.append(.{ hm.get("in").?, conds });

    outer: while (true) {
        const c = tmp.popOrNull() orelse break;
        const cur = c[0];
        var cds = c[1];
        for (cur.conds) |cond| {
            if (cond.elem != null) {
                if (cond.go[0] != 'R') {
                    var cc = try cds.clone();
                    try cc.append(C{
                        .elem = cond.elem.?,
                        .val = cond.val.?,
                        .cmp = cond.cmp.?,
                    });
                    if (cond.go[0] == 'A') {
                        try final.append(try cc.toOwnedSlice());
                    } else {
                        try tmp.append(.{ hm.get(cond.go).?, cc });
                    }
                }
                const cmp: u8 = if (cond.cmp.? == '<') 'g' else 'l';
                try cds.append(.{
                    .elem = cond.elem.?,
                    .val = cond.val.?,
                    .cmp = cmp,
                });
            } else {
                if (cond.go[0] == 'R') continue :outer;
                if (cond.go[0] == 'A') {
                    try final.append(try cds.toOwnedSlice());
                    continue :outer;
                }

                try tmp.append(.{ hm.get(cond.go).?, cds });
            }
        }
    }

    const ff = try final.toOwnedSlice();
    var rr: usize = 0;
    for (ff) |f| {
        var nxmin: usize = 1;
        var nxmax: usize = 4000;
        var nmmin: usize = 1;
        var nmmax: usize = 4000;
        var namin: usize = 1;
        var namax: usize = 4000;
        var nsmin: usize = 1;
        var nsmax: usize = 4000;
        for (f) |c| {
            switch (c.elem) {
                'x' => {
                    if (c.cmp == '<') {
                        nxmax = c.val - 1;
                    } else if (c.cmp == '>') {
                        nxmin = c.val + 1;
                    } else if (c.cmp == 'l') {
                        nxmax = c.val;
                    } else if (c.cmp == 'g') {
                        nxmin = c.val;
                    } else unreachable;
                },
                'm' => {
                    if (c.cmp == '<') {
                        nmmax = c.val - 1;
                    } else if (c.cmp == '>') {
                        nmmin = c.val + 1;
                    } else if (c.cmp == 'l') {
                        nmmax = c.val;
                    } else if (c.cmp == 'g') {
                        nmmin = c.val;
                    } else unreachable;
                },
                'a' => {
                    if (c.cmp == '<') {
                        namax = c.val - 1;
                    } else if (c.cmp == '>') {
                        namin = c.val + 1;
                    } else if (c.cmp == 'l') {
                        namax = c.val;
                    } else if (c.cmp == 'g') {
                        namin = c.val;
                    } else unreachable;
                },
                's' => {
                    if (c.cmp == '<') {
                        nsmax = c.val - 1;
                    } else if (c.cmp == '>') {
                        nsmin = c.val + 1;
                    } else if (c.cmp == 'l') {
                        nsmax = c.val;
                    } else if (c.cmp == 'g') {
                        nsmin = c.val;
                    } else unreachable;
                },
                else => unreachable,
            }
        }
        rr += (nxmax - nxmin + 1) * (nmmax - nmmin + 1) * (namax - namin + 1) * (nsmax - nsmin + 1);
    }

    return rr;
}

pub fn parse(input: []const u8) !Game {
    var rules = std.ArrayList(Rule).init(alloc);
    var entries = std.ArrayList(Entry).init(alloc);
    var lines = std.mem.tokenizeSequence(u8, input, "\n\n");

    const up = lines.next().?;
    const down = lines.next().?;

    var up_lines = std.mem.tokenizeScalar(u8, up, '\n');
    var down_lines = std.mem.tokenizeScalar(u8, down, '\n');

    while (up_lines.next()) |ul| {
        var split = std.mem.tokenizeScalar(u8, ul, '{');
        const name = split.next().?;
        const rest = split.next().?;
        var rest_split = std.mem.tokenizeScalar(u8, rest[0 .. rest.len - 1], ',');

        var cond = std.ArrayList(Cond).init(alloc);
        while (rest_split.next()) |rs| {
            if (std.mem.count(u8, rs, ":") > 0) {
                var rs_split = std.mem.tokenizeScalar(u8, rs, ':');
                const left = rs_split.next().?;
                const right = rs_split.next().?;
                const elem = left[0];
                const cmp = left[1];
                const val = try std.fmt.parseInt(usize, left[2..], 10);

                try cond.append(Cond{
                    .go = right,
                    .cmp = cmp,
                    .val = val,
                    .elem = elem,
                });
            } else {
                try cond.append(Cond{
                    .go = rs,
                });
            }
        }
        try rules.append(Rule{
            .name = name,
            .conds = try cond.toOwnedSlice(),
        });
    }
    while (down_lines.next()) |dl| {
        var split = std.mem.tokenizeScalar(u8, dl, ',');
        const x = split.next().?;
        const m = split.next().?;
        const a = split.next().?;
        const s = split.next().?;

        try entries.append(Entry{
            .x = try std.fmt.parseInt(usize, x[3..], 10),
            .m = try std.fmt.parseInt(usize, m[2..], 10),
            .a = try std.fmt.parseInt(usize, a[2..], 10),
            .s = try std.fmt.parseInt(usize, s[2 .. s.len - 1], 10),
        });
    }

    return Game{
        .rules = try rules.toOwnedSlice(),
        .entries = try entries.toOwnedSlice(),
    };
}

const test_data =
    \\px{a<2006:qkq,m>2090:A,rfg}
    \\pv{a>1716:R,A}
    \\lnx{m>1548:A,A}
    \\rfg{s<537:gd,x>2440:R,A}
    \\qs{s>3448:A,lnx}
    \\qkq{x<1416:A,crn}
    \\crn{x>2662:A,R}
    \\in{s<1351:px,qqz}
    \\qqz{s>2770:qs,m<1801:hdj,R}
    \\gd{a>3333:R,R}
    \\hdj{m>838:A,pv}
    \\
    \\{x=787,m=2655,a=1222,s=2876}
    \\{x=1679,m=44,a=2067,s=496}
    \\{x=2036,m=264,a=79,s=2244}
    \\{x=2461,m=1339,a=466,s=291}
    \\{x=2127,m=1623,a=2188,s=1013}
;

test "test-1" {
    const res: usize = try solve1(try parse(test_data));
    try std.testing.expectEqual(res, 19114);
}

test "test-2" {
    const res: usize = try solve2(try parse(test_data));
    try std.testing.expectEqual(res, 167409079868000);
}
