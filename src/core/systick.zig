const mmio = @import("mmio.zig");

const RELOAD_VALUE = 125000 - 1; // 1 ms at 125 MHz
const ENABLE_BITMASK = 0x7;

pub fn init() void {
    mmio.systick.rvr = RELOAD_VALUE;
    mmio.systick.csr = ENABLE_BITMASK;
}
