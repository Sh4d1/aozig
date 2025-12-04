const std = @import("std");

/// Simple growable FIFO queue for arbitrary types.
pub fn Fifo(comptime T: type) type {
    return struct {
        const Self = @This();

        alloc: std.mem.Allocator,
        list: std.array_list.Aligned(T, null) = .empty,
        head: usize = 0,

        /// Creates an empty queue that owns allocations via `alloc`.
        pub fn init(alloc: std.mem.Allocator) Self {
            return .{ .alloc = alloc };
        }

        /// Releases buffered storage.
        pub fn deinit(self: *Self) void {
            self.list.deinit(self.alloc);
        }

        /// Returns true when no items remain.
        pub fn isEmpty(self: Self) bool {
            return self.head >= self.list.items.len;
        }

        /// Returns the number of elements waiting to be popped.
        pub fn len(self: Self) usize {
            return self.list.items.len - self.head;
        }

        /// Appends an item to the tail of the queue.
        pub fn push(self: *Self, value: T) !void {
            try self.list.append(self.alloc, value);
        }

        /// Appends a slice of items to the tail of the queue.
        pub fn pushSlice(self: *Self, values: []const T) !void {
            try self.list.appendSlice(self.alloc, values);
        }

        /// Pops the next item from the head of the queue.
        pub fn pop(self: *Self) ?T {
            if (self.head >= self.list.items.len) {
                self.reset();
                return null;
            }
            const value = self.list.items[self.head];
            self.head += 1;
            if (self.head >= self.list.items.len) {
                self.reset();
            } else if (self.head > self.list.items.len / 2 and self.head > 16) {
                self.compact();
            }
            return value;
        }

        fn compact(self: *Self) void {
            const remaining = self.list.items[self.head..];
            @memmove(self.list.items[0..remaining.len], remaining);
            self.list.items.len = remaining.len;
            self.head = 0;
        }

        fn reset(self: *Self) void {
            self.list.clearRetainingCapacity();
            self.head = 0;
        }
    };
}

test "fifo maintains FIFO order" {
    var fifo = Fifo(u32).init(std.testing.allocator);
    defer fifo.deinit();

    try fifo.push(1);
    try fifo.push(2);
    try std.testing.expectEqual(@as(?u32, 1), fifo.pop());
    try fifo.pushSlice(&[_]u32{ 3, 4, 5, 6 });
    try std.testing.expectEqual(@as(usize, 5), fifo.len());
    try std.testing.expectEqual(@as(?u32, 2), fifo.pop());
    try std.testing.expectEqual(@as(?u32, 3), fifo.pop());
    try std.testing.expectEqual(@as(usize, 3), fifo.len());
}
