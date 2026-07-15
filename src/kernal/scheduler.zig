const core = @import("core");
const mmio = core.mmio;
const task = @import("task.zig");

const SYSTICK_RELOAD_VALUE = 125000 - 1; // 1 ms for 125MHz
const SYSTICK_ENABLE_BITMASK = 0x7;

const PENDSVSET = 1 << 28;
const PENDSV_PRI_LOWEST = 0b11 << 22;

const MAX_TASKS: usize = 8;
var tasks: [MAX_TASKS]task.Task = undefined;
var task_count: usize = 0;

pub fn registerTask(name: []const u8, entry: *const fn () void) void {
    tasks[task_count] = .{
        .name = name,
        .entry = entry,
        .state = .Ready,
    };
    task_count += 1;
}

fn initSystick() void {
    mmio.systick.rvr = SYSTICK_RELOAD_VALUE;
    mmio.systick.csr = SYSTICK_ENABLE_BITMASK;
}

fn setPendSVPriority() void {
    mmio.scb.shpr3 |= PENDSV_PRI_LOWEST;
}

inline fn setPendSVPending() void {
    mmio.scb.icsr = PENDSVSET;
}

var TICK_COUNTER: u32 = 0;

pub fn sysTickISR() callconv(.c) void {
    TICK_COUNTER += 1;
    if (TICK_COUNTER < 1000) return;
    TICK_COUNTER = 0;

    setPendSVPending();
}

pub fn pendsvISR() callconv(.c) void {
    core.gpio.toggleLED();
    core.uart.w_interface.print("hello UART!\n\r", .{}) catch {};
}

pub fn start() void {
    setPendSVPriority();
    initSystick();
}
