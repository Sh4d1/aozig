const std = @import("std");
pub var alloc = std.heap.page_allocator;

const Game = struct {
    bid: usize,
    cards: [5]u8,
    hand: [14]u8,

    pub fn score(self: Game) usize {
        var max: usize = 0;
        var smax: usize = 0;
        for (self.hand) |count| {
            if (count > max) {
                smax = max;
                max = count;
            } else if (count > smax) {
                smax = count;
            }
        }
        smax -= std.mem.count(u8, &self.cards, &[_]u8{0});

        return switch (max) {
            // five
            5 => 6,
            // four
            4 => 5,
            // full: 4, three: 3, smax(full) > smax(three)
            3 => smax + 2,
            // two pair: 2, pair: 1
            2 => smax,
            // high card
            1 => 0,
            else => unreachable,
        };
    }

    pub fn beats(self: Game, other: Game) bool {
        if (self.score() > other.score()) {
            return true;
        } else if (self.score() < other.score()) {
            return false;
        }

        for (self.cards, 0..) |c, i| {
            if (c > other.cards[i]) {
                return true;
            } else if (c < other.cards[i]) {
                return false;
            }
        }

        unreachable;
    }
};

pub fn sort(a: []Game, b: []Game) void {
    for (0..a.len) |i| b[i] = a[i];
    split_merge(b, 0, a.len, a);
}

fn split_merge(b: []Game, begin: usize, end: usize, a: []Game) void {
    if (end <= 1 + begin) return;
    const middle = (end + begin) / 2;
    split_merge(a, begin, middle, b);
    split_merge(a, middle, end, b);
    merge(b, begin, middle, end, a);
}

fn merge(a: []Game, begin: usize, middle: usize, end: usize, b: []Game) void {
    var i = begin;
    var j = middle;
    for (begin..end) |k| {
        if (i < middle and (j >= end or a[i].beats(a[j]))) {
            b[k] = a[i];
            i = i + 1;
        } else {
            b[k] = a[j];
            j = j + 1;
        }
    }
}

pub fn solve1(input: []Game) !usize {
    var res: usize = 0;
    const d: []Game = input;
    const r = try alloc.alloc(Game, input.len);
    sort(d, r);
    for (d, 0..) |h, i| {
        res += h.bid * (d.len - i);
    }
    return res;
}

pub fn solve2(input: []Game) !usize {
    var res: usize = 0;
    const d: []Game = input;
    const r = try alloc.alloc(Game, input.len);
    sort(d, r);
    for (d, 0..) |h, i| {
        res += h.bid * (d.len - i);
    }
    return res;
}

pub fn parse(input: []const u8) ![]Game {
    return parse_all(input, false);
}
pub fn parse2(input: []const u8) ![]Game {
    return parse_all(input, true);
}

pub fn parse_all(input: []const u8, p2: bool) ![]Game {
    var res = std.ArrayList(Game).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |l| {
        var split = std.mem.split(u8, l, " ");
        var cards = std.mem.zeroes([5]u8);
        var hand = std.mem.zeroes([14]u8);

        for (split.next().?, 0..) |c, i| {
            var value: u8 = switch (c) {
                '2'...'9' => c - '2' + 1,
                'T' => 9,
                'J' => 10,
                'Q' => 11,
                'K' => 12,
                'A' => 13,
                else => unreachable,
            };
            if (c == 'J' and p2) {
                value = 0;
                for (0..hand.len) |j| {
                    hand[j] += 1;
                }
            } else {
                hand[value] += 1;
            }
            cards[i] = value;
        }
        try res.append(Game{
            .bid = try std.fmt.parseInt(usize, split.next().?, 10),
            .hand = hand,
            .cards = cards,
        });
    }

    return res.toOwnedSlice();
}

const test_data =
    \\32T3K 765
    \\T55J5 684
    \\KK677 28
    \\KTJJT 220
    \\QQQJA 483
;

test "test-1" {
    const res: usize = try solve1(try parse(test_data));
    try std.testing.expectEqual(res, 6440);
}

test "test-2" {
    const res: usize = try solve2(try parse2(test_data));
    try std.testing.expectEqual(res, 5905);
}
