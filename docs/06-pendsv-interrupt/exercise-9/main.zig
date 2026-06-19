const pico = @import("pico.zig");

var TICK_COUNTER: u32 = 0;

fn initSystick() void {
    pico.put32(pico.CORTEX_SYST_RVR, pico.SYSTICK_RELOAD_VALUE);
    pico.put32(pico.CORTEX_SYST_CSR, pico.SYSTICK_ENABLE_BITMASK);
}

fn setPendSVPriority() void {
    var curr = pico.get32(pico.CORTEX_SHPR3);
    curr |= 0b11 << 22; // 0b11 (3) is lowest priority
    pico.put32(pico.CORTEX_SHPR3, curr);
}

inline fn setPendSVPending() void {
    pico.put32(pico.CORTEX_ICSR, 1 << 28);
}

export fn isr_pendsv() void {
    pico.printf("SHPR3 = 0x%08lx\n", pico.get32(pico.CORTEX_SHPR3));
}

export fn isr_systick() void {
    TICK_COUNTER += 1;
    if (TICK_COUNTER < 1000) return;
    TICK_COUNTER = 0;

    setPendSVPending();
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
