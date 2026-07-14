const core = @import("core");
const mmio = core.mmio;

const SYSTICK_RELOAD_VALUE = 125000 - 1; // 1 ms for 125MHz
const SYSTICK_ENABLE_BITMASK = 0x7;

fn initSystick() void {
    mmio.systick.rvr = SYSTICK_RELOAD_VALUE;
    mmio.systick.csr = SYSTICK_ENABLE_BITMASK;
}

var TICK_COUNTER: u32 = 0;

pub fn isr_systick() callconv(.c) void {
    TICK_COUNTER += 1;
    if (TICK_COUNTER < 50) return;
    TICK_COUNTER = 0;

    core.gpio.toggleLED();
}

pub fn init() void {
    initSystick();
}
