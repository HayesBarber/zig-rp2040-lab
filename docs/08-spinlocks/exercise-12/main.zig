const pico = @import("pico.zig");

var GLOBAL_DATA: i32 = 0;
const ITERATIONS: u32 = 1_000_000;
var DONE: u8 = 0;

fn done() void {
    pico.spinlockGet(0);
    DONE += 1;
    pico.spinlockFree(0);
}

fn increment() void {
    pico.spinlockGet(7);
    const tmp = GLOBAL_DATA;
    pico.sleep_us(1);
    GLOBAL_DATA = tmp + 1;
    pico.spinlockFree(7);
}

fn core1Entry() callconv(.c) void {
    pico.printf("beginning core 1 iterations\n");
    var i: u32 = 0;
    while (i < ITERATIONS) : (i += 1) {
        increment();
    }
    pico.printf("core 1 iterations done\n");

    done();
    while (true) {}
}

export fn main() noreturn {
    pico.stdio_init_all();
    pico.ledInit();

    pico.sleep_ms(4000);

    pico.multicore_launch_core1(&core1Entry);

    pico.printf("beginning core 0 iterations\n");
    var i: u32 = 0;
    while (i < ITERATIONS) : (i += 1) {
        increment();
    }
    pico.printf("core 0 iterations done\n");

    done();

    while (@as(*volatile u8, &DONE).* < 2) {}

    pico.printf("Expected: %u\n", 2 * ITERATIONS);
    pico.printf("Actual:   %u\n", GLOBAL_DATA);

    while (true) {
        pico.toggleLED();
        pico.sleep_ms(1000);
    }
}
