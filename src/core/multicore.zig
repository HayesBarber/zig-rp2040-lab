const mmio = @import("mmio.zig");

const PSM_FRCE_OFF_PROC1: u32 = 1 << 16;

pub fn resetCore1() void {
    // Assert reset on core 1 via atomic set alias (offset 0x4, bit 16).
    mmio.psm_set.frce_off = PSM_FRCE_OFF_PROC1;

    // Poll until the bit reads back 1, confirming core 1 is held in reset.
    while (mmio.psm.frce_off & PSM_FRCE_OFF_PROC1 == 0) {}

    // Release reset via atomic clear alias.
    mmio.psm_clr.frce_off = PSM_FRCE_OFF_PROC1;

    // Core 1 drains its FIFO, then pushes a 0 to confirm it came out of reset.
    // Hard fault if the handshake value is anything else.
    const value = fifo.readBlocking();
    if (value != 0) {
        @trap();
    }
}

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
