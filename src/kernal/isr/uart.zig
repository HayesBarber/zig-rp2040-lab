const core = @import("core");
const scheduler = @import("../scheduler/mod.zig");
const SpinLock = @import("../mutual-exclusion/spin_lock.zig");

const RxBuffer = core.data_structures.ring_buffer.RingBuffer(u8, 128);

var rx_buffer: RxBuffer = .{};
var waiting_task: ?*anyopaque = null;
const lock: SpinLock = .init(1);

pub fn handler() void {
    if (!core.uart.receiveInterruptPending()) return;

    const guard = lock.acquire();
    defer guard.release();

    while (core.uart.readFifo()) |byte| {
        _ = rx_buffer.push(byte);
    }
    core.uart.clearReceiveInterrupts();

    if (waiting_task) |blocked_task| {
        scheduler.makeReady(blocked_task);
        // The wakeup consumes the single waiter slot. The resumed read only
        // clears this field if it still refers to itself, so it cannot erase
        // a newer waiter's registration.
        waiting_task = null;
    }
}

pub fn read(destination: []u8) usize {
    if (destination.len == 0) return 0;

    const guard = lock.acquire();

    const available = rx_buffer.read(destination);
    if (available != 0) {
        guard.release();
        return available;
    }

    if (waiting_task != null) @trap();
    const blocked_task = scheduler.blockCurrent();
    waiting_task = blocked_task;
    guard.release();
    core.pendsv.request();

    const resumed_guard = lock.acquire();
    defer resumed_guard.release();
    if (waiting_task == blocked_task) waiting_task = null;
    return rx_buffer.read(destination);
}
