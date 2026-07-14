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

pub fn print(msg: []const u8) void {
    for (msg) |c| {
        putChar(c);
    }
}
