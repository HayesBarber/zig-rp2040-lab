const core = @import("core");

comptime {
    @import("zrt0").init();
}

pub fn main() noreturn {
    core.gpio.ledInit();
    while (true) {
        core.gpio.toggleLED();
        var a: u32 = 150000;
        while (a > 0) : (a -= 1) {
            asm volatile ("nop");
        }
    }
}
