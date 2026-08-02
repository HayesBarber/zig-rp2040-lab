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
    var buffer: [16]u8 = undefined;
    while (true) {
        const count = kernal.uart.read(&buffer);
        for (buffer[0..count]) |byte| core.uart.putChar(byte);
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

pub const SCHEDULER_ALGORITHM = kernal.SchedulingAlgorithms.round_robin;
pub const SCHEDULER_MODE = kernal.SchedulerMode.single_core;

pub fn registerTasks() kernal.task.TaskGroup {
    return .{
        .task_entries = &.{
            .{ .name = "blink", .entry = blinkTask },
            .{ .name = "uart", .entry = uartTask },
            .{ .name = "compute", .entry = computeTask },
        },
    };
}
