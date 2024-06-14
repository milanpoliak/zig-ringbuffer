const std = @import("std");
const testing = std.testing;
const expect = testing.expect;

/// No allocation generic ring buffer for type `T` with capacity of `capacity`
pub fn RingBuffer(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();

        buffer: [capacity]T = undefined,
        read_index: usize = 0,
        write_index: usize = 0,
        capacity: usize = capacity,

        pub fn init() Self {
            return Self{};
        }

        /// Read the current item and advance the read pointer.
        /// Does not check the pointers and might corrupt the state or produce garbage values if reading past the write pointer.
        pub fn read(self: *Self) T {
            const current_index = self.read_index;
            self.read_index = @addWithOverflow(self.read_index, 1)[0];

            return self.buffer[current_index % capacity];
        }

        /// Try reading the current item and advancing the read pointer.
        /// If there is nothing to read, returns null.
        pub fn readChecked(self: *Self) ?T {
            if (!self.readyToRead()) {
                return null;
            }

            return self.read();
        }

        /// Check if there is anything to read.
        pub fn readyToRead(self: *Self) bool {
            return self.read_index != self.write_index;
        }

        /// Read the current value without advancing the read pointer.
        /// Does not check the pointers and might return garbage values if reading past the write pointer.
        pub fn peek(self: *Self) T {
            return self.buffer[self.read_index % capacity];
        }

        /// Write a value and advance the write pointer.
        /// Does not check the pointers and might skip past the read pointer, causing overwrites of yet unread values.
        pub fn write(self: *Self, item: T) void {
            self.buffer[self.write_index % capacity] = item;
            self.write_index = @addWithOverflow(self.write_index, 1)[0];
        }

        /// Try writing a value and advancing the write pointer.
        /// If the capacity is full, does nothing and returns false.
        pub fn writeChecked(self: *Self, item: T) bool {
            if (self.isFull()) {
                return false;
            }

            self.write(item);

            return true;
        }

        /// Check if buffer is full.
        pub fn isFull(self: *Self) bool {
            return self.size() == capacity;
        }

        /// Calculate the number of items currently stored.
        pub fn size(self: *Self) usize {
            if (self.write_index < self.read_index) {
                return @subWithOverflow(self.write_index, self.read_index)[0];
            }

            return self.write_index - self.read_index;
        }

        /// Reset both write and read pointers.
        /// Does *not* zero out the memory.
        pub fn clear(self: *Self) void {
            self.write_index = 0;
            self.read_index = 0;
        }
    };
}

fn testBuffer() RingBuffer(u16, 10) {
    const buff = RingBuffer(u16, 10).init();

    return buff;
}

fn randomInt() u16 {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });

    return prng.random().int(u16);
}

test "empty buffer does not have read available" {
    var buffer = testBuffer();

    try expect(buffer.readyToRead() == false);
}

test "empty buffer is not full" {
    var buffer = testBuffer();

    try expect(buffer.isFull() == false);
}

test "empty buffer has size of 0" {
    var buffer = testBuffer();

    try expect(buffer.size() == 0);
}

test "checked reading from empty buffer returns null" {
    var buffer = testBuffer();
    const result = buffer.readChecked();

    try expect(result == null);
}

test "full buffer is full" {
    var buffer = testBuffer();

    for (0..buffer.capacity) |i| {
        buffer.write(@intCast(i));
    }

    try expect(buffer.isFull() == true);
    try expect(buffer.size() == buffer.capacity);
}

test "writing into buffer increases the size" {
    var buffer = testBuffer();

    buffer.write(69);
    buffer.write(420);

    try expect(buffer.size() == 2);
}

test "reading from the buffer decreases the size" {
    var buffer = testBuffer();

    buffer.write(69);
    buffer.write(420);

    _ = buffer.read();

    try expect(buffer.size() == 1);
}

test "writing and reading stores and produces correct values" {
    var buffer = testBuffer();

    for (0..buffer.capacity * 2) |_| {
        const int = randomInt();

        buffer.write(int);

        try expect(buffer.read() == int);
    }
}

test "clear empties the buffer" {
    var buffer = testBuffer();

    for (0..buffer.capacity) |_| {
        buffer.write(randomInt());
    }

    try expect(buffer.size() == buffer.capacity);

    buffer.clear();

    try expect(buffer.size() == 0);
    try expect(buffer.readyToRead() == false);
}

test "peek returns the current item" {
    var buffer = testBuffer();

    buffer.write(69);
    buffer.write(420);

    _ = buffer.read();

    try expect(buffer.peek() == 420);
}