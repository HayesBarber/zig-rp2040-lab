const pico = @import("pico.zig");

export fn main() noreturn {
    pico.stdio_init_all();
    pico.ledInit();
    pico.initSystick();

    while (true) {
        pico.printf("Hello timer!: %ld\n", pico.TICK_COUNTER);
        pico.toggleLED();
        pico.sleep_ms(500);
    }
}
