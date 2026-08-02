const mmio = @import("mmio.zig");

const PSM_FRCE_OFF_PROC1: u32 = 1 << 16;
const CORE1_STACK_SIZE = 1024;

pub const Core1Entry = *const fn () noreturn;

var core1_stack: [CORE1_STACK_SIZE]u8 align(8) = undefined;

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

pub fn launchCore1(entry: Core1Entry) void {
    resetCore1();

    const stack_pointer = prepareCore1Stack(entry);
    const sequence = [_]u32{
        0,
        0,
        1,
        mmio.scb.vtor,
        stack_pointer,
        @intFromPtr(&core1Trampoline),
    };

    var index: usize = 0;
    while (index < sequence.len) {
        const value = sequence[index];

        if (value == 0) fifo.drain();

        fifo.writeBlocking(value);
        if (fifo.readBlocking() == value) {
            index += 1;
        } else {
            index = 0;
        }
    }
}

fn prepareCore1Stack(entry: Core1Entry) u32 {
    const stack_bottom = @intFromPtr(&core1_stack);
    const stack_top = stack_bottom + core1_stack.len;
    const frame: *[3]u32 = @ptrFromInt(stack_top - @sizeOf([3]u32));

    // `core1Trampoline` pops these into r0, r1, and pc respectively.
    frame[0] = @intFromPtr(entry);
    frame[1] = @intCast(stack_bottom);
    frame[2] = @intFromPtr(&core1Wrapper);

    return @intCast(@intFromPtr(frame));
}

fn core1Trampoline() callconv(.naked) void {
    asm volatile ("pop {r0, r1, pc}");
}

fn core1Wrapper(entry: Core1Entry, stack_base: usize) noreturn {
    _ = stack_base;
    entry();
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
