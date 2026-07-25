const core = @import("core");
const scheduler = @import("scheduler/mod.zig");
const task = @import("task.zig");

const RxBuffer = core.data_structures.ring_buffer.RingBuffer(u8, 128);

var rx_buffer: RxBuffer = .{};
var waiting_task: ?*task.TCB = null;

pub fn read(destination: []u8) usize {
    if (destination.len == 0) return 0;

    core.interrupts.disable();
    const available = rx_buffer.read(destination);
    if (available != 0) {
        core.interrupts.enable();
        return available;
    }

    if (waiting_task != null) @trap();
    waiting_task = scheduler.blockCurrent();
    core.interrupts.enable();

    waiting_task = null;
    return rx_buffer.read(destination);
}

pub fn handleInterrupt() void {
    if (!core.uart.receiveInterruptPending()) return;

    while (core.uart.readFifo()) |byte| {
        _ = rx_buffer.push(byte);
    }
    core.uart.clearReceiveInterrupts();

    if (waiting_task) |blocked_task| {
        scheduler.makeReady(blocked_task);
    }
}
