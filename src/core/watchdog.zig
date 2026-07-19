const mmio = @import("mmio.zig");

const TICK_ENABLE_BIT: u32 = 1 << 9;
const CTRL_ENABLE_BIT: u32 = 1 << 30;
const MAX_LOAD: u32 = 0x00ff_ffff;
const PSM_WDSEL_ALL: u32 = 0x0001_ffff;
const PSM_WDSEL_ROSC_AND_XOSC: u32 = 0x3;

pub fn configure() void {
    disable();

    // clk_ref is the 12 MHz XOSC, so 12 input cycles produce a 1 MHz tick.
    mmio.watchdog.tick = TICK_ENABLE_BIT | 12;

    // Reset all eligible blocks except the clocks that generate the watchdog tick.
    mmio.psm.wdsel = PSM_WDSEL_ALL & ~PSM_WDSEL_ROSC_AND_XOSC;
    mmio.watchdog.load = MAX_LOAD;
}

pub fn enable() void {
    mmio.watchdog.ctrl |= CTRL_ENABLE_BIT;
}

pub fn feed() void {
    mmio.watchdog.load = MAX_LOAD;
}

pub fn disable() void {
    mmio.watchdog.ctrl &= ~CTRL_ENABLE_BIT;
}
