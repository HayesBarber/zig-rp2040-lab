const pico = @import("pico.zig");

export fn main() noreturn {
    pico.stdio_init_all();
    pico.ledInit();

    while (true) {
        pico.printf("Hello timer!\n");
        pico.toggleLED();
        pico.sleep_ms(500);
    }
}
