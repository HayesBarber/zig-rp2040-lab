const root = @import("root");
const core = @import("core");
const mmio = core.mmio;
const task = @import("task.zig");

pub const TCB = task.TCB;

const SYSTICK_RELOAD_VALUE = 125000 - 1; // 1 ms for 125MHz
const SYSTICK_ENABLE_BITMASK = 0x7;

const PENDSVSET = 1 << 28;
const PENDSV_PRI_LOWEST = 0b11 << 22;

const TASKS = blk: {
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
var ticks: u32 = 0;

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
    ticks += 1;
    if (ticks < 1000) return;
    ticks = 0;

    setPendSVPending();
}

pub fn pendsvISR() callconv(.naked) void {}

pub fn start() noreturn {
    setPendSVPriority();
    initSysTick();

    while (true) {
        for (&TASKS) |t| {
            t.entry();
        }
    }
}
