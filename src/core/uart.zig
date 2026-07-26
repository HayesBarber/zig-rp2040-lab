const std = @import("std");
const mmio = @import("mmio.zig");

pub const UART0_IRQ = 20;

const RX_INTERRUPT = 1 << 4;
const RECEIVE_TIMEOUT_INTERRUPT = 1 << 6;
const RECEIVE_INTERRUPTS = RX_INTERRUPT | RECEIVE_TIMEOUT_INTERRUPT;

pub fn initUart() void {
    mmio.resets_clr.reset = 1 << 22;
    while ((mmio.resets.reset_done & (1 << 22)) == 0) {}

    mmio.iobank0.gpio[0].ctrl = 2;
    mmio.iobank0.gpio[1].ctrl = 2;

    mmio.uart0.cr = 0;

    mmio.uart0.ibrd = 67;
    mmio.uart0.fbrd = 52;

    mmio.uart0.lcr_h = (1 << 4) | (3 << 5);

    mmio.uart0.cr = (1 << 0) | (1 << 8) | (1 << 9);

    mmio.uart0.icr = RECEIVE_INTERRUPTS;
    mmio.uart0.ifls &= ~@as(u32, 0b111 << 3);
    mmio.uart0.imsc |= RECEIVE_INTERRUPTS;
    mmio.nvic.iser = 1 << UART0_IRQ;
}

pub fn putChar(c: u8) void {
    while ((mmio.uart0.fr & (1 << 5)) != 0) {}
    mmio.uart0.dr = c;
}

pub fn readFifo() ?u8 {
    if ((mmio.uart0.fr & (1 << 4)) != 0) return null;
    return @truncate(mmio.uart0.dr);
}

pub fn receiveInterruptPending() bool {
    return (mmio.uart0.mis & RECEIVE_INTERRUPTS) != 0;
}

pub fn clearReceiveInterrupts() void {
    mmio.uart0.icr = RECEIVE_INTERRUPTS;
}

fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
    _ = w;
    var total: usize = 0;
    for (data[0 .. data.len - 1]) |buf| {
        for (buf) |c| putChar(c);
        total += buf.len;
    }
    const pattern = data[data.len - 1];
    for (0..splat) |_| {
        for (pattern) |c| putChar(c);
        total += pattern.len;
    }
    return total;
}

pub var w_interface = std.Io.Writer{
    .vtable = &.{
        .drain = drain,
        .flush = std.Io.Writer.noopFlush,
    },
    .buffer = &.{},
};
