const core = @import("core");
const memory = core.memory;

const SYSTICK_RELOAD_VALUE = 125000 - 1; // 1 ms
const SYSTICK_ENABLE_BITMASK = 0x7;

fn initSystick() void {
    memory.putAddr(memory.CORTEX_SYST_RVR, SYSTICK_RELOAD_VALUE);
    memory.putAddr(memory.CORTEX_SYST_CSR, SYSTICK_ENABLE_BITMASK);
}

var TICK_COUNTER: u32 = 0;

pub fn isr_systick() void {
    TICK_COUNTER += 1;
    if (TICK_COUNTER < 2000) return;
    TICK_COUNTER = 0;

    core.gpio.turnOffLED();
}

pub fn start() void {
    initSystick();
}
