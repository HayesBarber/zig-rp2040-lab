const mmio = @import("mmio.zig");

pub const fifo = struct {
    pub fn canRead() bool {
        return mmio.multi_core_fifo.st & 1 == 1;
    }

    pub fn read() ?u32 {
        if (!canRead()) return null;

        return mmio.multi_core_fifo.rd;
    }

    pub fn readBlocking() u32 {
        while (true) {
            if (read()) |val| return val;
            asm volatile ("wfe");
        }
    }

    pub fn drain() void {
        while (read()) {}
    }

    pub fn canWrite() bool {
        return mmio.multi_core_fifo.st & (1 << 1) == 1;
    }

    pub fn write(value: u32) void {
        mmio.multi_core_fifo.wr = value;
        asm volatile ("sev");
    }

    pub fn writeBlocking(value: u32) void {
        while (!canWrite()) {}
        write(value);
    }
};
