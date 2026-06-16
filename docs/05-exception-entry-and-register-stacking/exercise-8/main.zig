const pico = @import("pico.zig");

var TICK_COUNTER: u32 = 0;

export fn isr_systick() callconv(.naked) void {
    asm volatile (
        \\ mrs r0, msp
        \\ ldr r1, =isr_systick_impl
        \\ bx r1
    );
}

export fn isr_systick_impl(frame: [*]const u32) void {
    TICK_COUNTER += 1;
    if (TICK_COUNTER < 1000) return;
    TICK_COUNTER = 0;

    pico.printf(
        "r0=%08x r1=%08x r2=%08x r3=%08x " ++ "r12=%08x lr=%08x pc=%08x xpsr=%08x\n",
        frame[0],
        frame[1],
        frame[2],
        frame[3],
        frame[4],
        frame[5],
        frame[6],
        frame[7],
    );
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
