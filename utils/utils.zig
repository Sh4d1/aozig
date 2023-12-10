const std = @import("std");
fn AllIterator(comptime T: type) type {
    return struct {
        i: usize,
        j: usize,
        grid: Grid(T),
        started: bool,

        const Self = @This();

        pub fn x(self: Self) usize {
            return self.i;
        }
        pub fn y(self: Self) usize {
            return self.j;
        }
        pub fn init(grid: Grid(T)) Self {
            return Self{
                .i = 0,
                .j = 0,
                .grid = grid,
                .started = false,
            };
        }

        pub fn next(self: *Self) ?T {
            if (!self.started) {
                self.started = true;
                return self.grid.data[self.i][self.j];
            }
            self.j += 1;
            if (self.j == self.grid.width) {
                self.j = 0;
                self.i += 1;
            }
            if (self.i == self.grid.height) {
                return null;
            }

            return self.grid.data[self.i][self.j];
        }
    };
}
fn SquareIterator(comptime T: type) type {
    return struct {
        ix: usize,
        jx: usize,
        i: usize,
        j: usize,
        grid: Grid(T),
        started: bool,

        const Self = @This();
        pub fn x(self: Self) usize {
            return self.i + self.ix - 1;
        }
        pub fn y(self: Self) usize {
            return self.j + self.jx - 1;
        }

        pub fn init(grid: Grid(T), i: usize, j: usize) Self {
            return Self{
                .ix = 0,
                .jx = 0,
                .i = i,
                .j = j,
                .grid = grid,
                .started = false,
            };
        }

        pub fn next(self: *Self) ?T {
            if (self.i + self.ix - 1 < 0) {
                self.ix += 1;
            }
            if (self.j + self.jx - 1 < 0) {
                self.jx += 1;
            }
            if (!self.started) {
                if (self.i + self.ix - 1 < 0) {
                    self.ix += 1;
                }
                if (self.j + self.jx - 1 < 0) {
                    self.jx += 1;
                }

                self.started = true;
                std.debug.print("{} {}\n", .{ self.i + self.ix - 1, self.j + self.jx - 1 });
                return self.grid.data[self.i + self.ix - 1][self.j + self.jx - 1];
            }

            self.jx += 1;

            if (self.j + self.jx - 1 == self.grid.width) {
                self.jx = 0;
                self.ix += 1;
            }
            if (self.j + self.jx - 1 < 0) {
                self.jx += 1;
            }

            if (self.i + self.ix - 1 == self.grid.height) {
                return null;
            }

            return self.grid.data[self.i + self.ix - 1][self.j + self.jx - 1];
        }
    };
}

// most likely have perf issues
pub fn Grid(comptime T: type) type {
    return struct {
        height: usize,
        width: usize,
        data: [][]T,

        const Self = @This();

        pub fn init(data: [][]T) Self {
            return .{
                .height = data.len,
                .width = data[0].len,
                .data = data,
            };
        }

        // will copy the data
        pub fn square3(self: Self, i: usize, j: usize) SquareIterator(T) {
            return SquareIterator(T).init(self, i, j);
        }

        // will copy the data
        pub fn all(self: Self) AllIterator(T) {
            return AllIterator(T).init(self);
        }
    };
}
