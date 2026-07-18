const core = @import("core");

const PENDSVSET = 1 << 28;
const PENDSV_PRI_LOWEST = 0b11 << 22;

pub inline fn request() void {
    core.mmio.scb.icsr = PENDSVSET;
}

pub fn setLowestPriority() void {
    core.mmio.scb.shpr3 |= PENDSV_PRI_LOWEST;
}
