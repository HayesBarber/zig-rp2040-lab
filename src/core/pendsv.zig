const mmio = @import("mmio.zig");

const PENDSVSET = 1 << 28;
const PENDSV_PRI_LOWEST = 0b11 << 22;

pub inline fn request() void {
    mmio.scb.icsr = PENDSVSET;
}

pub fn setLowestPriority() void {
    mmio.scb.shpr3 |= PENDSV_PRI_LOWEST;
}
