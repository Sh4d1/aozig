const std = @import("std");

/// Possible errors produced while parsing or constructing grids.
pub const GridError = error{
    EmptyGrid,
    InconsistentRowWidth,
};

/// Zero-based coordinates used to address a grid cell.
pub const Coord = struct {
    row: usize,
    col: usize,
};

/// Returns a concrete grid type specialized for the provided element type.
pub fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();

        width: usize,
        height: usize,
        data: []T,

        /// Allocates a new grid with the same dimensions but a different element type.
        pub fn newFrom(self: Self, comptime TG: type, alloc: std.mem.Allocator) !Grid(TG) {
            const data = try alloc.alloc(TG, self.width * self.height);
            return Grid(TG){
                .width = self.width,
                .height = self.height,
                .data = data,
            };
        }

        /// Releases the underlying buffer.
        pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
            alloc.free(self.data);
        }

        /// Writes `value` to the `(row, col)` location.
        pub fn set(self: *Self, row: usize, col: usize, value: T) void {
            self.data[row * self.width + col] = value;
        }

        /// Writes `value` to the provided coordinate.
        pub fn setCoord(self: *Self, coord: Coord, value: T) void {
            self.set(coord.row, coord.col, value);
        }

        /// Returns the value stored at `(row, col)`.
        pub fn get(self: Self, row: usize, col: usize) T {
            return self.data[row * self.width + col];
        }

        /// Returns the value stored at the coordinate.
        pub fn getCoord(self: Self, coord: Coord) T {
            return self.get(coord.row, coord.col);
        }

        /// Counts how many neighbors around `(row, col)` equal `value`.
        pub fn countAdjacent(self: Self, row: usize, col: usize, value: T) u8 {
            var neighbor_it = self.neighborIter(.{ .row = row, .col = col });
            var count: u8 = 0;
            while (neighbor_it.next()) |coord| {
                if (self.getCoord(coord) == value) count += 1;
            }
            return count;
        }

        /// Counts neighbors matching `value` around `coord`.
        pub fn countAdjacentCoord(self: Self, coord: Coord, value: T) u8 {
            return self.countAdjacent(coord.row, coord.col, value);
        }

        /// Parses a rectangular grid by applying `convert` to each character.
        pub fn parse(alloc: std.mem.Allocator, text: []const u8, convert: anytype) !Self {
            var builder: std.array_list.Aligned(T, null) = .empty;

            var width: ?usize = null;
            var height: usize = 0;
            var lines = std.mem.splitScalar(u8, text, '\n');
            while (lines.next()) |raw_line| {
                const line = std.mem.trim(u8, raw_line, "\r ");
                if (line.len == 0) continue;
                if (width) |w| {
                    if (line.len != w) return GridError.InconsistentRowWidth;
                } else {
                    width = line.len;
                }

                for (line, 0..) |ch, col| {
                    const converted = convert(height, col, ch);
                    const value = switch (@typeInfo(@TypeOf(converted))) {
                        .error_union => try converted,
                        else => converted,
                    };
                    try builder.append(alloc, value);
                }
                height += 1;
            }

            if (width == null or height == 0) return GridError.EmptyGrid;

            const cells = try builder.toOwnedSlice(alloc);
            return .{
                .width = width.?,
                .height = height,
                .data = cells,
            };
        }

        /// Returns an iterator that yields every cell and its coordinates.
        pub fn iter(self: Self) Iterator {
            return .{ .grid = self };
        }

        pub const Iterator = struct {
            pub const Item = struct {
                coord: Coord,
                value: T,
            };

            grid: Self,
            next_idx: usize = 0,

            pub fn next(self: *Iterator) ?Item {
                if (self.next_idx >= self.grid.data.len) return null;
                const idx = self.next_idx;
                self.next_idx += 1;
                const row = idx / self.grid.width;
                const col = idx % self.grid.width;
                return Item{
                    .coord = .{ .row = row, .col = col },
                    .value = self.grid.data[idx],
                };
            }
        };

        /// Returns an iterator over the 8 adjacent cells (clamped at edges).
        pub fn neighborIter(self: Self, coord: Coord) NeighborIterator {
            const row_start = if (coord.row == 0) coord.row else coord.row - 1;
            const row_end = if (coord.row + 1 >= self.height) self.height - 1 else coord.row + 1;
            const col_start = if (coord.col == 0) coord.col else coord.col - 1;
            const col_end = if (coord.col + 1 >= self.width) self.width - 1 else coord.col + 1;
            return NeighborIterator{
                .center = coord,
                .row = row_start,
                .col = col_start,
                .row_start = row_start,
                .row_end = row_end,
                .col_start = col_start,
                .col_end = col_end,
                .done = false,
            };
        }

        pub const NeighborIterator = struct {
            center: Coord,
            row: usize,
            col: usize,
            row_start: usize,
            row_end: usize,
            col_start: usize,
            col_end: usize,
            done: bool,

            pub fn next(self: *NeighborIterator) ?Coord {
                if (self.done) return null;
                while (true) {
                    const result = Coord{ .row = self.row, .col = self.col };
                    if (self.col == self.col_end) {
                        self.col = self.col_start;
                        if (self.row == self.row_end) {
                            self.done = true;
                        } else {
                            self.row += 1;
                        }
                    } else {
                        self.col += 1;
                    }
                    if (result.row == self.center.row and result.col == self.center.col) {
                        if (self.done) return null;
                        continue;
                    }
                    return result;
                }
            }
        };
    };
}

/// Convenience wrapper for parsing a `[width][height]` grid of bytes.
pub fn parseByteGrid(alloc: std.mem.Allocator, text: []const u8) !Grid(u8) {
    return Grid(u8).parse(alloc, text, struct {
        fn convert(_: usize, _: usize, ch: u8) u8 {
            return ch;
        }
    }.convert);
}

test "parse" {
    var grid = try parseByteGrid(std.testing.allocator,
        \\abc
        \\def
    );
    defer grid.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 3), grid.width);
    try std.testing.expectEqual(@as(usize, 2), grid.height);
    try std.testing.expectEqual(@as(u8, 'a'), grid.get(0, 0));
    try std.testing.expectEqual(@as(u8, 'f'), grid.get(1, 2));
    grid.set(1, 1, 'x');
    try std.testing.expectEqual(@as(u8, 'x'), grid.get(1, 1));
}

test "parse convert" {
    var grid = try Grid(u8).parse(std.testing.allocator,
        \\12
        \\34
    , struct {
        fn convert(_: usize, _: usize, ch: u8) u8 {
            return ch - '0';
        }
    }.convert);
    defer grid.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(u8, 1), grid.get(0, 0));
    try std.testing.expectEqual(@as(u8, 4), grid.get(1, 1));
}

test "iterator walks entire grid" {
    var grid = try parseByteGrid(std.testing.allocator,
        \\ab
        \\cd
    );
    defer grid.deinit(std.testing.allocator);

    var seen = std.bit_set.IntegerBitSet(4).initEmpty();
    var it = grid.iter();
    while (it.next()) |item| {
        const idx = item.coord.row * grid.width + item.coord.col;
        seen.set(idx);
        switch (idx) {
            0 => try std.testing.expectEqual(@as(u8, 'a'), item.value),
            1 => try std.testing.expectEqual(@as(u8, 'b'), item.value),
            2 => try std.testing.expectEqual(@as(u8, 'c'), item.value),
            3 => try std.testing.expectEqual(@as(u8, 'd'), item.value),
            else => unreachable,
        }
    }
    try std.testing.expectEqual(@as(usize, 4), seen.count());
}

test "neighbor iterator enumerates adjacent cells" {
    var grid = try parseByteGrid(std.testing.allocator,
        \\abc
        \\def
        \\ghi
    );
    defer grid.deinit(std.testing.allocator);

    var iter = grid.neighborIter(.{ .row = 1, .col = 1 });
    var buf: [8]u8 = undefined;
    var idx: usize = 0;
    while (iter.next()) |coord| : (idx += 1) {
        buf[idx] = grid.getCoord(coord);
    }
    try std.testing.expectEqual(@as(usize, 8), idx);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 'a', 'b', 'c', 'd', 'f', 'g', 'h', 'i' }, buf[0..idx]);

    var neighbour_iter = grid.neighborIter(.{ .row = 0, .col = 0 });
    var neighbour_count: usize = 0;
    while (neighbour_iter.next()) |_| neighbour_count += 1;
    try std.testing.expectEqual(@as(usize, 3), neighbour_count);
}

test "newFrom" {
    var grid = try parseByteGrid(std.testing.allocator,
        \\12
        \\34
    );
    defer grid.deinit(std.testing.allocator);

    var scratch = try grid.newFrom(u32, std.testing.allocator);
    defer scratch.deinit(std.testing.allocator);
    try std.testing.expectEqual(grid.width, scratch.width);
    try std.testing.expectEqual(grid.height, scratch.height);
    scratch.set(1, 1, 42);
    try std.testing.expectEqual(@as(u32, 42), scratch.get(1, 1));
}
