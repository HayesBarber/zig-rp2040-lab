const std = @import("std");
const mmio = @import("mmio.zig");

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
}

pub fn putChar(c: u8) void {
    while ((mmio.uart0.fr & (1 << 5)) != 0) {}
    mmio.uart0.dr = c;
}

pub fn getChar() u8 {
    while ((mmio.uart0.fr & (1 << 4)) != 0) {}
    return @truncate(mmio.uart0.dr);
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
