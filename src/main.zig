const core = @import("core");
const kernal = @import("kernal");

comptime {
    @import("zrt0").init();
}

fn blinkTask() void {
    core.gpio.toggleLED();
}

fn uartTask() void {
    core.uart.w_interface.print("*", .{}) catch {};
}

fn computeTask() void {
    var i: u32 = 0;
    while (i < 50000) : (i += 1) {
        asm volatile ("nop");
    }
}

pub fn setup() void {
    kernal.scheduler.registerTask("blink", blinkTask);
    kernal.scheduler.registerTask("uart", uartTask);
    kernal.scheduler.registerTask("compute", computeTask);
}
