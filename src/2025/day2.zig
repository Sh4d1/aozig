const std = @import("std");
const aozig = @import("aozig");

pub var alloc: std.mem.Allocator = std.heap.page_allocator;

pub fn parse(input: []const u8) ![][2]usize {
    var res: std.array_list.Aligned([2]usize, null) = .empty;
    defer res.deinit(alloc);
    var ranges = std.mem.splitAny(u8, input, ",\n");
    while (ranges.next()) |range| {
        if (range.len == 0) continue;
        var seq = std.mem.splitAny(u8, range, "-");
        const first = try std.fmt.parseInt(usize, seq.next() orelse unreachable, 10);
        const last = try std.fmt.parseInt(usize, seq.next() orelse unreachable, 10);
        _ = try res.append(alloc, [2]usize{ first, last });
    }
    return res.toOwnedSlice(alloc);
}

fn numDigits(n: usize) usize {
    if (n == 0) return 1;
    return std.math.log10_int(n) + 1;
}

pub fn solve1(input: [][2]usize) usize {
    var res: usize = 0;
    for (input) |range| {
        const start = range[0];
        const end = range[1];

        const min_len = numDigits(start);
        const max_len = numDigits(end);

        if (@mod(min_len, 2) == 1 and min_len == max_len) continue;

        var first_part = @divFloor(start, std.math.pow(usize, 10, min_len / 2));
        if (@mod(min_len, 2) == 1) {
            first_part = std.math.pow(usize, 10, (min_len + 1) / 2 - 1);
        }

        // We construct each invalid ID possible with the first part we have
        // And we keep incrementing it if in range
        while (true) {
            const n = first_part * std.math.pow(usize, 10, numDigits(first_part)) + first_part;
            if (n > end) break;
            first_part += 1;
            if (n < start) continue;
            res += n;
        }
    }
    return res;
}

fn isPeriodic(n: usize) bool {
    const len = numDigits(n);
    if (len < 2) return false;

    var pat_len: usize = 1;
    while (pat_len <= len / 2) : (pat_len += 1) {
        if (len % pat_len == 0) {
            const multiplier = buildMultiplier(pat_len, len);
            if (n % multiplier == 0) {
                return true;
            }
        }
    }
    return false;
}

fn buildMultiplier(pat_len: usize, total_len: usize) usize {
    var m: usize = 0;
    var i: usize = 0;
    while (i < total_len) : (i += pat_len) {
        m = m * std.math.pow(usize, 10, pat_len) + 1;
    }
    return m;
}

pub fn solve2(input: [][2]usize) !usize {
    // initial very slow (20s) but working first version of p2
    // var res: usize = 0;
    // for (input) |i| {
    //     for (i[0]..i[1] + 1) |x| {
    //         var concat = try std.fmt.allocPrint(alloc, "{d}{d}", .{ x, x });
    //         if (std.mem.containsAtLeast(u8, concat[1 .. concat.len - 1], 1, try std.fmt.allocPrint(alloc, "{d}", .{x}))) {
    //             res += x;
    //         }
    //     }
    // }
    // return res;

    // This new solution is rather optimized compared to the first one
    // We want to generate those invalid IDs instead of checking each one
    // Which is basically like p1, but harder
    // We use "multipliers" which are for instance 101 -> 12*101 = 1212, 1001001 -> 451*1001001 = 451451

    var total_sum: usize = 0;

    for (input) |range| {
        const start = range[0];
        const end = range[1];

        const min_len = numDigits(start);
        const max_len = numDigits(end);

        var n_len = min_len;
        while (n_len <= max_len) : (n_len += 1) {
            var pat_len: usize = 1;
            while (pat_len <= n_len / 2) : (pat_len += 1) {
                if (n_len % pat_len != 0) continue;

                const multiplier = buildMultiplier(pat_len, n_len);

                // start <= seed * multiplier <= end
                const min_seed = try std.math.divCeil(usize, start, multiplier);
                const max_seed = end / multiplier;

                const seed_lower_bound = std.math.pow(usize, 10, pat_len - 1);
                const seed_upper_bound = std.math.pow(usize, 10, pat_len) - 1;

                const actual_start = @max(min_seed, seed_lower_bound);
                const actual_end = @min(max_seed, seed_upper_bound);

                if (actual_start > actual_end) continue;

                var seed: usize = actual_start;
                while (seed <= actual_end) : (seed += 1) {
                    // to avoid couting same periodic seeds (111, 11, 1 for instance)
                    if (!isPeriodic(seed)) {
                        total_sum += seed * multiplier;
                    }
                }
            }
        }
    }
    return total_sum;
}

test "example" {
    const input =
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
    ;
    const i = try parse(input);
    try std.testing.expectEqual(@as(usize, 1227775554), solve1(i));
    try std.testing.expectEqual(@as(usize, 4174379265), try solve2(i));
}
