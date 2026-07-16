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
    while (i < 5_000_000) : (i += 1) {
        asm volatile ("nop");
    }
}

pub fn setup() kernal.task.TaskGroup {
    return .{
        .task_entries = &.{
            .{ .name = "blink", .entry = blinkTask },
            .{ .name = "uart", .entry = uartTask },
            .{ .name = "compute", .entry = computeTask },
        },
    };
}
