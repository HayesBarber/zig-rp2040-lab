const mmio = @import("mmio.zig");

// mirrors MicroZig: https://github.com/ZigEmbeddedGroup/microzig/blob/main/port/raspberrypi/rp2xxx/src/hal/multicore.zig#L14
pub const fifo = struct {
    pub fn canRead() bool {
        return mmio.inter_core_fifo.st & 1 == 1;
    }

    pub fn read() ?u32 {
        if (!canRead()) return null;

        return mmio.inter_core_fifo.rd;
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
        return mmio.inter_core_fifo.st & (1 << 1) == 1;
    }

    pub fn write(value: u32) void {
        mmio.inter_core_fifo.wr = value;
        asm volatile ("sev");
    }

    pub fn writeBlocking(value: u32) void {
        while (!canWrite()) {}
        write(value);
    }
};
