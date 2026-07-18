const core = @import("core");

pub fn handler() callconv(.c) noreturn {
    while (true) {
        core.gpio.toggleLED();
        var delay: usize = 0;
        while (delay < 2_000_000) : (delay += 1) asm volatile ("nop");
    }
}
