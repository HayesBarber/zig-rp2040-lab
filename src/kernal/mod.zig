pub const heap = @import("heap.zig");
pub const isr = @import("isr/mod.zig");
pub const scheduler = @import("scheduler/mod.zig");
pub const task = @import("task.zig");
pub const uart = @import("isr/uart.zig");

pub fn start() noreturn {
    heap.init();
    scheduler.start();
}
