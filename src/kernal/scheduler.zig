const root = @import("root");
const core = @import("core");
const mmio = core.mmio;
const task = @import("task.zig");

pub const TCB = task.TCB;

const SYSTICK_RELOAD_VALUE = 125000 - 1; // 1 ms for 125MHz
const SYSTICK_ENABLE_BITMASK = 0x7;

const PENDSVSET = 1 << 28;
const PENDSV_PRI_LOWEST = 0b11 << 22;

var TASKS = blk: {
    const group = root.setup();
    var arr: [group.task_entries.len]TCB = undefined;
    for (&arr, group.task_entries) |*t, e| {
        t.* = .{
            .name = e.name,
            .entry = e.entry,
        };
    }
    break :blk arr;
};
var current_task_idx: usize = 0;

fn initSysTick() void {
    mmio.systick.rvr = SYSTICK_RELOAD_VALUE;
    mmio.systick.csr = SYSTICK_ENABLE_BITMASK;
}

fn setPendSVPriority() void {
    mmio.scb.shpr3 |= PENDSV_PRI_LOWEST;
}

inline fn setPendSVPending() void {
    mmio.scb.icsr = PENDSVSET;
}

pub fn sysTickISR() void {
    TASKS[current_task_idx].remaining_ticks -= 1;
    if (TASKS[current_task_idx].remaining_ticks == 0) {
        setPendSVPending();
    }
}

export fn taskExit() callconv(.c) noreturn {
    while (true) {
        setPendSVPending();
        asm volatile ("wfi");
    }
}

export fn schedulerSelectNext() callconv(.c) usize {
    TASKS[current_task_idx].state = .Ready;
    const next = (current_task_idx + 1) % TASKS.len;
    current_task_idx = next;
    TASKS[next].state = .Running;
    TASKS[next].remaining_ticks = TASKS[next].quantum;
    return TASKS[next].sp;
}

pub export fn pendsvISR() callconv(.naked) void {
    asm volatile (
        \\mrs r0, psp
        \\subs r0, r0, #32
        \\stmia r0!, {r4-r7}
        \\mov r4, r8
        \\mov r5, r9
        \\mov r6, r10
        \\mov r7, r11
        \\stmia r0!, {r4-r7}
        \\subs r0, r0, #32
        \\bl schedulerSelectNext
        \\mov r1, r0
        \\adds r1, r1, #16
        \\ldmia r1!, {r4-r7}
        \\mov r8, r4
        \\mov r9, r5
        \\mov r10, r6
        \\mov r11, r7
        \\ldmia r0!, {r4-r7}
        \\adds r0, r0, #16
        \\msr psp, r0
        \\ldr r0, =0xFFFFFFFD
        \\mov lr, r0
        \\bx lr
    );
}

pub fn hardFault() callconv(.c) noreturn {
    while (true) {
        core.gpio.toggleLED();
        var d: usize = 0;
        while (d < 2_000_000) : (d += 1) asm volatile ("nop");
    }
}

pub fn start() noreturn {
    setPendSVPriority();

    for (&TASKS) |*t| {
        const stack_top = @intFromPtr(&t.stack) + TCB.STACK_SIZE;

        // Reserve:
        //   32 bytes for r4-r11 (saved by PendSV)
        //   32 bytes for hardware exception frame
        const sp = stack_top - 64;

        // Hardware exception frame
        const hw = @as(*[8]u32, @ptrFromInt(sp + 32));
        hw.* = .{
            0, // R0
            0, // R1
            0, // R2
            0, // R3
            0, // R12
            @intFromPtr(&taskExit) | 1, // LR
            @intFromPtr(t.entry) | 1, // PC
            0x01000000, // xPSR (Thumb bit)
        };

        // Software-saved registers.
        @as(*[8]u32, @ptrFromInt(sp)).* = .{
            0, 0, 0, 0, // r4-r7
            0, 0, 0, 0, // r8-r11
        };

        t.sp = sp;
        t.remaining_ticks = t.quantum;
    }

    asm volatile ("msr psp, %[sp]"
        :
        : [sp] "r" (TASKS[0].sp),
    );

    initSysTick();
    setPendSVPending();
    while (true) asm volatile ("wfi");
}
