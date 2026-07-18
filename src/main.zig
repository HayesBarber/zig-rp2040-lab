const core = @import("core");
const kernal = @import("kernal");

comptime {
    @import("zrt0").init();
}

fn blinkTask() noreturn {
    while (true) {
        core.gpio.toggleLED();

        var i: u32 = 0;
        while (i < 6_000_000) : (i += 1) {
            asm volatile ("nop");
        }
    }
}

fn uartTask() noreturn {
    while (true) {
        core.uart.w_interface.print("*", .{}) catch {};

        var i: u32 = 0;
        while (i < 4_000_000) : (i += 1) {
            asm volatile ("nop");
        }
    }
}

fn computeTask() noreturn {
    while (true) {
        var i: u32 = 0;
        while (i < 5_000_000) : (i += 1) {
            asm volatile ("nop");
        }
    }
}

pub fn registerTasks() kernal.task.TaskGroup {
    return .{
        .task_entries = &.{
            .{ .name = "blink", .entry = blinkTask },
            .{ .name = "uart", .entry = uartTask },
            .{ .name = "compute", .entry = computeTask },
        },
    };
}
