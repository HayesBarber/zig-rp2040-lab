pub const isr = @import("isr/mod.zig");
pub const scheduler = @import("scheduler/mod.zig");
pub const task = @import("task.zig");

pub fn start() noreturn {
    scheduler.start();
}
