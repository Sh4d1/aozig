const std = @import("std");
const time = std.time;
const A = std.mem.Allocator;

/// Default heap size for day solutions (100MB)
pub const default_heap_size: usize = 100 * 1024 * 1024;

/// Executes Advent of Code day solutions with timing information.
pub fn run(comptime days: anytype) !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    var day: ?usize = null;
    if (args.len > 1) {
        if (std.mem.eql(u8, args[1], "bench")) {
            var nruns: usize = 10;
            if (args.len > 2) {
                nruns = try std.fmt.parseInt(usize, args[2], 10);
            }
            const buffer = try std.heap.page_allocator.alloc(u8, default_heap_size);
            defer std.heap.page_allocator.free(buffer);
            var fba = std.heap.FixedBufferAllocator.init(buffer);

            return bench(days, fba.allocator(), nruns);
        }
        if (std.mem.eql(u8, args[1], "heap")) {
            return heap(days);
        }
        day = try std.fmt.parseInt(usize, args[1], 10);
    }

    var total: i128 = 0;
    inline for (days) |info| {
        var should_run = true;
        if (day) |requested| {
            should_run = requested == info.day;
        }
        if (should_run) {
            const input_data = try readInput(info.input_path);
            defer std.heap.page_allocator.free(input_data);

            const buffer = try std.heap.page_allocator.alloc(u8, default_heap_size);
            defer std.heap.page_allocator.free(buffer);
            var fba = std.heap.FixedBufferAllocator.init(buffer);

            if (day) |_| {
                _ = try runDay(fba.allocator(), info.module, info.day, input_data, true);
            } else {
                total += try runDay(fba.allocator(), info.module, info.day, input_data, true);
            }
        }
    }

    if (args.len == 1) {
        std.debug.print("Finished {any} days in {d:.5}ms\n", .{ days.len, @as(f64, @floatFromInt(total)) / 1000000.0 });
    }
}

fn runDay(alloc: A, comptime module: type, comptime day: usize, data: []const u8, comptime print: bool) !i128 {
    if (@hasDecl(module, "alloc")) {
        module.alloc = alloc;
    }

    if (print) std.debug.print("day{any}:", .{day});

    const start = time.nanoTimestamp();
    const input = try module.parse(data);
    const parse = time.nanoTimestamp() - start;
    if (print) std.debug.print(" parsing:{d:.5}ms", .{@as(f64, @floatFromInt(parse)) / 1000000.0});

    const startp1 = time.nanoTimestamp();
    const s1 = module.solve1(input);
    const p1 = time.nanoTimestamp() - startp1;
    if (print) std.debug.print(" p1:{d:.5}ms", .{@as(f64, @floatFromInt(p1)) / 1000000.0});

    if (@hasDecl(module, "parse2")) {
        const startparse2 = time.nanoTimestamp();
        const input2 = try module.parse2(data);
        const parse2 = time.nanoTimestamp() - startparse2;
        if (print) std.debug.print(" parsing2:{d:.5}ms", .{@as(f64, @floatFromInt(parse2)) / 1000000.0});
        const startp2 = time.nanoTimestamp();
        const s2 = module.solve2(input2);
        const p2 = time.nanoTimestamp() - startp2;
        if (print) std.debug.print(" p2:{d:.5}ms\n", .{@as(f64, @floatFromInt(p2)) / 1000000.0});
        if (print) std.debug.print("day{any}: p1: {any} p2: {any}\n", .{ day, s1, s2 });
        return parse + p1 + parse2 + p2;
    } else {
        const startp2 = time.nanoTimestamp();
        const s2 = module.solve2(input);
        const p2 = time.nanoTimestamp() - startp2;
        if (print) std.debug.print(" p2:{d:.5}ms\n", .{@as(f64, @floatFromInt(p2)) / 1000000.0});
        if (print) std.debug.print("day{any}: p1: {any} p2: {any}\n", .{ day, s1, s2 });
        return parse + p1 + p2;
    }
}

/// Statistical benchmark results for a single day
const DayBench = struct {
    min: i128,
    max: i128,
    mean: i128,
    median: i128,
    stddev: i128,
};

/// Runs statistical benchmarks on all day solutions.
pub fn bench(comptime days: anytype, alloc: A, n: usize) !void {
    var res = std.mem.zeroes([days.len]DayBench);
    var totals_list: std.array_list.Aligned(i128, null) = .empty;
    defer totals_list.deinit(alloc);
    for (1..n) |_| {
        try totals_list.append(alloc, 0);
    }
    var totals = try totals_list.toOwnedSlice(alloc);

    inline for (days, 0..) |info, idx| {
        var runs_list: std.array_list.Aligned(i128, null) = .empty;
        defer runs_list.deinit(alloc);

        const input_data = try readInput(info.input_path);
        defer std.heap.page_allocator.free(input_data);

        for (0..n - 1) |j| {
            var arena = std.heap.ArenaAllocator.init(alloc);
            const t = try runDay(arena.allocator(), info.module, info.day, input_data, false);
            arena.deinit();
            try runs_list.append(alloc, t);
            totals[j] += t;
        }
        const runs = try runs_list.toOwnedSlice(alloc);
        std.sort.insertion(i128, runs, void{}, std.sort.asc(i128));

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
        res[idx] = b;
    }

    std.debug.print("Ran with {} runs\n", .{n});
    std.debug.print("┌────────┬────────────┬────────────┬────────────┬────────────┬────────────┐\n", .{});
    std.debug.print("│  Days  │    Min     │    Max     │    Mean    │   Median   │   Stddev   │\n", .{});
    std.debug.print("├────────┼────────────┼────────────┼────────────┼────────────┼────────────┤\n", .{});
    inline for (days, 0..) |info, idx| {
        const b = res[idx];
        std.debug.print("│{d: ^8}│{d: >8.2}ms  │{d: >8.2}ms  │{d: >8.2}ms  │{d: >8.2}ms  │{d: >8.2}ms  │\n", .{
            info.day,
            @as(f64, @floatFromInt(b.min)) / 1000000.0,
            @as(f64, @floatFromInt(b.max)) / 1000000.0,
            @as(f64, @floatFromInt(b.mean)) / 1000000.0,
            @as(f64, @floatFromInt(b.median)) / 1000000.0,
            @as(f64, @floatFromInt(b.stddev)) / 1000000.0,
        });
        std.debug.print("├────────┼────────────┼────────────┼────────────┼────────────┼────────────┤\n", .{});
    }
    std.sort.insertion(i128, totals, void{}, std.sort.asc(i128));
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

    std.debug.print("│  Total │{d: >8.2}ms  │{d: >8.2}ms  │{d: >8.2}ms  │{d: >8.2}ms  │{d: >8.2}ms  │\n", .{
        @as(f64, @floatFromInt(min)) / 1000000.0,
        @as(f64, @floatFromInt(max)) / 1000000.0,
        @as(f64, @floatFromInt(mean)) / 1000000.0,
        @as(f64, @floatFromInt(median)) / 1000000.0,
        @as(f64, @floatFromInt(stddev)) / 1000000.0,
    });
    std.debug.print("└────────┴────────────┴────────────┴────────────┴────────────┴────────────┘\n", .{});
}

/// Analyzes minimum heap requirements for each day solution.
/// Uses binary search to find the smallest buffer size that allows successful execution.
pub fn heap(comptime days: anytype) !void {
    const start_heap = 5000000;
    var good_heap: usize = start_heap;
    var bad_heap: usize = 0;
    var h: usize = start_heap;
    var total: usize = 0;

    inline for (days) |info| {
        if (!@hasDecl(info.module, "alloc")) {
            std.debug.print("day{}: no heap\n", .{info.day});
            continue;
        }
        h = start_heap;
        good_heap = h;
        bad_heap = 0;
        const input_data = try readInput(info.input_path);
        defer std.heap.page_allocator.free(input_data);

        const heap_size = while (true) {
            const buffer = try std.heap.page_allocator.alloc(u8, h);
            defer std.heap.page_allocator.free(buffer);
            var fba = std.heap.FixedBufferAllocator.init(buffer);
            const alloc = fba.allocator();

            if (runDay(alloc, info.module, info.day, input_data, false)) |_| {
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
        std.debug.print("day{}: {d:.3}KB\n", .{ info.day, @as(f64, @floatFromInt(heap_size)) / 1000.0 });
        total += heap_size;
    }
    std.debug.print("total: {d:.3}MB\n", .{@as(f64, @floatFromInt(total)) / 1000000.0});
}

fn readInput(path: []const u8) ![]u8 {
    var file = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });
    defer file.close();
    return try file.readToEndAlloc(std.heap.page_allocator, std.math.maxInt(usize));
}
