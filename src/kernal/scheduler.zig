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
    const gpio_xor: *volatile u32 = @ptrFromInt(0xd000001c);

    while (true) {
        var i: usize = 0;
        while (i < 3) : (i += 1) {
            gpio_xor.* = (1 << 25);
            var d: usize = 0;
            while (d < 3_000_000) : (d += 1) asm volatile ("nop");
        }
        var g: usize = 0;
        while (g < 1_000_000) : (g += 1) asm volatile ("nop");
        i = 0;
        while (i < 3) : (i += 1) {
            gpio_xor.* = (1 << 25);
            var d: usize = 0;
            while (d < 10_000_000) : (d += 1) asm volatile ("nop");
        }
        g = 0;
        while (g < 1_000_000) : (g += 1) asm volatile ("nop");
        i = 0;
        while (i < 3) : (i += 1) {
            gpio_xor.* = (1 << 25);
            var d: usize = 0;
            while (d < 3_000_000) : (d += 1) asm volatile ("nop");
        }
        var p: usize = 0;
        while (p < 15_000_000) : (p += 1) asm volatile ("nop");
    }
}

pub fn start() noreturn {
    setPendSVPriority();

    for (&TASKS) |*t| {
        const sp = @intFromPtr(&t.stack) + TCB.STACK_SIZE - 32;
        @as(*[8]u32, @ptrFromInt(sp)).* = .{
            0x01000000,
            @intFromPtr(t.entry),
            @intFromPtr(&taskExit),
            0,
            0,
            0,
            0,
            0,
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
