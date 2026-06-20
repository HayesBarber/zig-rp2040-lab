const pico = @import("pico.zig");

fn core1Entry() callconv(.c) void {
    while (true) {
        pico.printf("Hello from core 1\n");
        pico.sleep_ms(1000);
    }
}

export fn main() noreturn {
    pico.stdio_init_all();
    pico.ledInit();

    pico.multicore_launch_core1(&core1Entry);

    while (true) {
        pico.toggleLED();
        pico.sleep_ms(1000);
    }
}
