const pico = @import("pico.zig");

var TICK_COUNTER: u32 = 0;

pub fn initSystick() void {
    pico.put32(pico.CORTEX_SYST_RVR, pico.SYSTICK_RELOAD_VALUE);
    pico.put32(pico.CORTEX_SYST_CSR, pico.SYSTICK_ENABLE_BITMASK);
}

pub fn setPendSVPriority() void {
    var curr = pico.get32(pico.CORTEX_SHPR3);
    curr |= 0b11 << 22; // 0b11 (3) is lowest priority
    pico.put32(pico.CORTEX_SHPR3, curr);
}

export fn isr_systick() void {
    TICK_COUNTER += 1;
    if (TICK_COUNTER < 1000) return;
    TICK_COUNTER = 0;
}

export fn main() noreturn {
    pico.stdio_init_all();
    pico.ledInit();
    setPendSVPriority();
    initSystick();

    while (true) {
        pico.toggleLED();
        pico.sleep_ms(2000);
    }
}
