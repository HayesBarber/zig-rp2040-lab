const uart = @import("../uart.zig");

pub fn handler() void {
    uart.handleInterrupt();
}
