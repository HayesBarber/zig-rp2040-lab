const pico = @import("pico.zig");

var TICK_COUNTER: u32 = 0;

export fn isr_systick() void {
    TICK_COUNTER += 1;
    if (TICK_COUNTER < 1000) return;
    TICK_COUNTER = 0;
}

export fn main() noreturn {
    pico.stdio_init_all();
    pico.ledInit();
    pico.initSystick();

    while (true) {
        pico.toggleLED();
        pico.sleep_ms(2000);
    }
}
