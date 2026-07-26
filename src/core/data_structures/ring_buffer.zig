pub fn RingBuffer(comptime T: type, comptime capacity: usize) type {
    if (capacity == 0) @compileError("ring buffer capacity must be non-zero");

    return struct {
        const Self = @This();

        storage: [capacity]T = undefined,
        read_index: usize = 0,
        write_index: usize = 0,
        count: usize = 0,

        pub fn push(self: *Self, value: T) bool {
            if (self.count == capacity) return false;

            self.storage[self.write_index] = value;
            self.write_index = (self.write_index + 1) % capacity;
            self.count += 1;
            return true;
        }

        pub fn pop(self: *Self) ?T {
            if (self.count == 0) return null;

            const value = self.storage[self.read_index];
            self.read_index = (self.read_index + 1) % capacity;
            self.count -= 1;
            return value;
        }

        pub fn read(self: *Self, destination: []T) usize {
            var written: usize = 0;
            while (written < destination.len) : (written += 1) {
                destination[written] = self.pop() orelse break;
            }
            return written;
        }
    };
}
