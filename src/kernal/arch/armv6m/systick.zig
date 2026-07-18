const core = @import("core");

const RELOAD_VALUE = 125000 - 1; // 1 ms at 125 MHz
const ENABLE_BITMASK = 0x7;

pub fn init() void {
    core.mmio.systick.rvr = RELOAD_VALUE;
    core.mmio.systick.csr = ENABLE_BITMASK;
}
