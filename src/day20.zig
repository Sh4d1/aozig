const std = @import("std");
pub var alloc = std.heap.page_allocator;

const ModuleTag = enum {
    ff,
    conj,
    brd,
};

const Module = union(ModuleTag) {
    ff: bool,
    conj: std.StringArrayHashMap(Pulse),
    brd,
};

const Pulse = enum {
    high,
    low,
};

const Inst = struct {
    name: []const u8,
    module: Module,
    out: [][]const u8,
};

pub fn solve1(_input: []Inst) !usize {
    const input = _input;
    var hm = std.StringHashMap(Inst).init(alloc);
    for (input) |r| {
        try hm.put(r.name, r);
    }
    for (input) |r| {
        for (r.out) |ro| {
            if (hm.get(ro)) |rr| {
                switch (rr.module) {
                    ModuleTag.conj => try hm.getPtr(ro).?.module.conj.put(r.name, Pulse.low),
                    else => {},
                }
            }
        }
    }

    var low: usize = 0;
    var high: usize = 0;
    for (0..1000) |_| {
        var fifo = std.fifo.LinearFifo(struct { []const u8, Pulse, ?[]const u8 }, .Dynamic).init(alloc);
        try fifo.writeItem(.{ "broadcaster", Pulse.low, null });

        while (fifo.readItem()) |i| {
            const cur = i[0];
            const pulse = i[1];

            if (pulse == Pulse.low) low += 1 else high += 1;

            var ptr = hm.getPtr(cur) orelse continue;

            switch (ptr.module) {
                ModuleTag.brd => for (ptr.out) |co| try fifo.writeItem(.{ co, pulse, cur }),
                ModuleTag.ff => |ff| {
                    if (pulse == Pulse.high) continue;
                    const to_send = if (ff) Pulse.low else Pulse.high;
                    for (ptr.out) |co| try fifo.writeItem(.{ co, to_send, cur });
                    ptr.module.ff = !ff;
                },
                ModuleTag.conj => {
                    try ptr.module.conj.put(i[2].?, pulse);
                    const all_high = for (ptr.module.conj.values()) |v| {
                        if (v == Pulse.low) break false;
                    } else true;
                    const to_send = if (all_high) Pulse.low else Pulse.high;
                    for (ptr.out) |co| try fifo.writeItem(.{ co, to_send, cur });
                },
            }
        }
    }
    return low * high;
}

pub fn solve2(_input: []Inst) !usize {
    const input = _input;
    var rx_in: []const u8 = undefined;
    var rx_src = std.StringArrayHashMap(?usize).init(alloc);
    var hm = std.StringHashMap(Inst).init(alloc);
    for (input) |r| {
        for (r.out) |ro| {
            if (std.mem.eql(u8, ro, "rx")) rx_in = r.name;
        }
        try hm.put(r.name, r);
    }
    for (input) |r| {
        for (r.out) |ro| {
            if (std.mem.eql(u8, ro, rx_in)) try rx_src.put(r.name, null);
            if (hm.get(ro)) |rr| {
                switch (rr.module) {
                    ModuleTag.conj => try hm.getPtr(ro).?.module.conj.put(r.name, Pulse.low),
                    else => {},
                }
            }
        }
    }

    var j: usize = 0;
    while (true) {
        j += 1;

        if (for (rx_src.values()) |v| {
            if (v == null) break false;
        } else true) {
            break;
        }

        var fifo = std.fifo.LinearFifo(struct { []const u8, Pulse, ?[]const u8 }, .Dynamic).init(alloc);
        try fifo.writeItem(.{ "broadcaster", Pulse.low, null });

        while (fifo.readItem()) |i| {
            const cur = i[0];
            const pulse = i[1];

            if (std.mem.eql(u8, cur, rx_in) and pulse == Pulse.high and rx_src.get(i[2].?).? == null) try rx_src.put(i[2].?, j);

            var ptr = hm.getPtr(cur) orelse continue;
            switch (ptr.module) {
                ModuleTag.brd => for (ptr.out) |co| try fifo.writeItem(.{ co, pulse, cur }),
                ModuleTag.ff => |ff| {
                    if (pulse == Pulse.high) continue;
                    const to_send = if (ff) Pulse.low else Pulse.high;
                    for (ptr.out) |co| try fifo.writeItem(.{ co, to_send, cur });
                    ptr.module.ff = !ff;
                },
                ModuleTag.conj => {
                    try ptr.module.conj.put(i[2].?, pulse);
                    const all_high = for (ptr.module.conj.values()) |v| {
                        if (v == Pulse.low) break false;
                    } else true;
                    const to_send = if (all_high) Pulse.low else Pulse.high;
                    for (ptr.out) |co| try fifo.writeItem(.{ co, to_send, cur });
                },
            }
        }
    }

    var res: usize = 1;
    for (rx_src.values()) |v| {
        res = res * v.? / std.math.gcd(res, v.?);
    }
    return res;
}

pub fn parse(input: []const u8) ![]Inst {
    var res = std.ArrayList(Inst).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        var split = std.mem.tokenizeSequence(u8, line, " -> ");
        const left = split.next().?;
        const right = split.next().?;
        const t: Module = if_label: {
            if (std.mem.eql(u8, left, "broadcaster")) {
                break :if_label Module{ .brd = void{} };
            } else if (left[0] == '%') {
                break :if_label Module{ .ff = false };
            } else if (left[0] == '&') {
                break :if_label Module{ .conj = std.StringArrayHashMap(Pulse).init(alloc) };
            } else unreachable;
        };

        var name: []const u8 = undefined;
        if (t != Module.brd) name = left[1..] else name = left;

        var res_out = std.ArrayList([]const u8).init(alloc);
        var out = std.mem.splitSequence(u8, right, ", ");
        while (out.next()) |o| {
            try res_out.append(o);
        }

        try res.append(Inst{
            .name = name,
            .module = t,
            .out = try res_out.toOwnedSlice(),
        });
    }

    return try res.toOwnedSlice();
}

const test_data =
    \\broadcaster -> a, b, c
    \\%a -> b
    \\%b -> c
    \\%c -> inv
    \\&inv -> a
;

const test_data_2 =
    \\broadcaster -> a
    \\%a -> inv, con
    \\&inv -> b
    \\%b -> con
    \\&con -> output
;

test "test-1" {
    const res: usize = try solve1(try parse(test_data));
    try std.testing.expectEqual(res, 32000000);
    const res2: usize = try solve1(try parse(test_data_2));
    try std.testing.expectEqual(res2, 11687500);
}
