const std = @import("std");
const time = std.time;
const A = std.mem.Allocator;

const days = [10]type{ @import("day1"), @import("day2"), @import("day3"), @import("day4"), @import("day5"), @import("day6"), @import("day7"), @import("day8"), @import("day9"), @import("day10") };

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    var day: ?usize = null;
    if (args.len > 1) {
        if (std.mem.eql(u8, args[1], "bench")) {
            var nruns: usize = 10;
            if (args.len > 2) {
                nruns = try std.fmt.parseInt(usize, args[2], 10);
            }
            // TODO: bench alloc
            return bench(std.heap.c_allocator, nruns);
        }
        if (std.mem.eql(u8, args[1], "heap")) {
            return heap();
        }
        day = try std.fmt.parseInt(usize, args[1], 10);
    }

    const alloc = std.heap.page_allocator;
    // const alloc = std.heap.c_allocator;

    // let's not bother with the memory leaks here
    const heap_size = 1550000;
    // var buffer: [heap_size]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const alloc = fba.allocator();

    var total: i128 = 0;
    inline for (days, 0..) |d, i| {
        if (day) |di| {
            if (di - 1 == i) {
                _ = try run(alloc, d, i + 1, true);
            }
        } else {
            total += try run(alloc, d, i + 1, true);
        }
    }

    if (args.len == 1) {
        std.debug.print("Finished {any} days in {d:.5}ms with {d:.5}MB of heap\n", .{ days.len, @as(f64, @floatFromInt(total)) / 1000000.0, @as(f64, @floatFromInt(heap_size)) / 1000000.0 });
    }
}

fn run(alloc: A, comptime d: type, comptime day: usize, comptime print: bool) !i128 {
    const data = @embedFile(std.fmt.comptimePrint("src/day{}.txt", .{day}));
    if (@hasDecl(d, "alloc")) {
        d.alloc = alloc;
    }

    if (@hasDecl(d, "parse2")) {
        const start = time.nanoTimestamp();
        const input = try d.parse(data);
        const parse = time.nanoTimestamp();
        const input2 = try d.parse2(data);
        const parse2 = time.nanoTimestamp();
        const s1 = d.solve1(input);
        const p1 = time.nanoTimestamp();
        const s2 = d.solve2(input2);
        const p2 = time.nanoTimestamp();

        if (print) {
            std.debug.print("day{any}: p1: {any} p2: {any}\n", .{ day, s1, s2 });
            std.debug.print("day{any}: parsing:{d:.5}ms parsing2:{d:.5}ms p1:{d:.5}ms p2:{d:.5}ms\n", .{ day, @as(f64, @floatFromInt(parse - start)) / 1000000.0, @as(f64, @floatFromInt(parse2 - parse)) / 1000000.0, @as(f64, @floatFromInt(p1 - parse)) / 1000000.0, @as(f64, @floatFromInt(p2 - p1)) / 1000000.0 });
        }
        return p2 - start;
    } else {
        const start = time.nanoTimestamp();
        const input = try d.parse(data);
        const parse = time.nanoTimestamp();
        const s1 = d.solve1(input);
        const p1 = time.nanoTimestamp();
        const s2 = d.solve2(input);
        const p2 = time.nanoTimestamp();

        if (print) {
            std.debug.print("day{any}: p1: {any} p2: {any}\n", .{ day, s1, s2 });
            std.debug.print("day{any}: parsing:{d:.5}ms p1:{d:.5}ms p2:{d:.5}ms\n", .{ day, @as(f64, @floatFromInt(parse - start)) / 1000000.0, @as(f64, @floatFromInt(p1 - parse)) / 1000000.0, @as(f64, @floatFromInt(p2 - p1)) / 1000000.0 });
        }
        return p2 - start;
    }
}

const DayBench = struct {
    min: i128,
    max: i128,
    mean: i128,
    median: i128,
    stddev: i128,
};

fn compare(_: void, a: i128, b: i128) bool {
    return a < b;
}

fn bench(alloc: A, n: usize) !void {
    var res = std.mem.zeroes([days.len]DayBench);
    var totals_list = std.ArrayList(i128).init(std.heap.page_allocator);
    for (1..n) |_| {
        try totals_list.append(0);
    }
    var totals = try totals_list.toOwnedSlice();

    inline for (days, 0..) |d, i| {
        var runs_list = std.ArrayList(i128).init(std.heap.page_allocator);

        for (0..n - 1) |j| {
            const t = try run(alloc, d, i + 1, false);
            try runs_list.append(t);
            totals[j] += t;
        }
        const runs = try runs_list.toOwnedSlice();
        std.sort.insertion(i128, runs, void{}, compare);

        var b = DayBench{
            .min = 0,
            .max = 0,
            .median = runs[runs.len / 2],
            .mean = 0,
            .stddev = 0,
        };
        for (runs) |rr| {
            const r: i128 = rr;
            if (b.min == 0 or r < b.min) b.min = r;
            if (r > b.max) b.max = r;
            b.mean += r;
        }
        b.mean = @divFloor(b.mean, runs.len);

        for (runs) |rr| b.stddev += (rr - b.mean) * (rr - b.mean);
        b.stddev = @divFloor(b.stddev, n - 1);
        b.stddev = @as(i128, @intFromFloat(std.math.floor(std.math.sqrt(@as(f64, @floatFromInt(b.stddev))))));
        res[i] = b;
    }

    std.debug.print("Ran with {} runs\n", .{n});
    std.debug.print("┌────────┬────────────┬────────────┬────────────┬────────────┬────────────┐\n", .{});
    std.debug.print("│  Days  │    Min     │    Max     │    Mean    │   Median   │   Stddev   │\n", .{});
    std.debug.print("├────────┼────────────┼────────────┼────────────┼────────────┼────────────┤\n", .{});
    for (res, 1..) |b, i| {
        std.debug.print("│{d: ^8}│{d: >8.2}ms  │{d: >8.2}ms  │{d: >8.2}ms  │{d: >8.2}ms  │{d: >8.2}ms  │\n", .{ i, @as(f64, @floatFromInt(b.min)) / 1000000.0, @as(f64, @floatFromInt(b.max)) / 1000000.0, @as(f64, @floatFromInt(b.mean)) / 1000000.0, @as(f64, @floatFromInt(b.median)) / 1000000.0, @as(f64, @floatFromInt(b.stddev)) / 1000000.0 });
        std.debug.print("├────────┼────────────┼────────────┼────────────┼────────────┼────────────┤\n", .{});
    }
    std.sort.insertion(i128, totals, void{}, compare);
    var max: i128 = 0;
    var min: i128 = 0;
    const median: i128 = totals[totals.len / 2];
    var mean: i128 = 0;
    var stddev: i128 = 0;
    for (totals) |t| {
        if (min == 0 or t < min) min = t;
        if (t > max) max = t;
        mean += t;
    }
    mean = @divFloor(mean, totals.len);
    for (totals) |t| stddev += (t - mean) * (t - mean);
    stddev = @divFloor(stddev, totals.len - 1);
    stddev = @as(i128, @intFromFloat(std.math.floor(std.math.sqrt(@as(f64, @floatFromInt(stddev))))));

    std.debug.print("│  Total │{d: >8.2}ms  │{d: >8.2}ms  │{d: >8.2}ms  │{d: >8.2}ms  │{d: >8.2}ms  │\n", .{ @as(f64, @floatFromInt(min)) / 1000000.0, @as(f64, @floatFromInt(max)) / 1000000.0, @as(f64, @floatFromInt(mean)) / 1000000.0, @as(f64, @floatFromInt(median)) / 1000000.0, @as(f64, @floatFromInt(stddev)) / 1000000.0 });
    std.debug.print("└────────┴────────────┴────────────┴────────────┴────────────┴────────────┘\n", .{});
}

fn heap() !void {
    const start_heap = 5000000;
    var good_heap: usize = start_heap;
    var bad_heap: usize = 0;
    var h: usize = start_heap;
    var total: usize = 0;

    inline for (days, 0..) |d, i| {
        if (@hasDecl(d, "alloc")) {
            h = start_heap;
            good_heap = h;
            bad_heap = 0;
            const heap_size = while (true) {
                const buffer = try std.heap.c_allocator.alloc(u8, h);
                var fba = std.heap.FixedBufferAllocator.init(buffer);
                const alloc = fba.allocator();

                if (run(alloc, d, i + 1, false)) |_| {
                    good_heap = h;
                    h -= (good_heap - bad_heap) / 2;
                } else |_| {
                    bad_heap = h;
                    h += (good_heap - bad_heap) / 2;
                }
                if (good_heap == bad_heap + 1 or good_heap == bad_heap) {
                    break good_heap;
                }
            };
            std.debug.print("day{}: {d:.3}KB\n", .{ i + 1, @as(f64, @floatFromInt(heap_size)) / 1000.0 });
            total += heap_size;
        } else {
            std.debug.print("day{}: no heap\n", .{i + 1});
        }
    }
    std.debug.print("total: {d:.3}MB\n", .{@as(f64, @floatFromInt(total)) / 1000000.0});
}
