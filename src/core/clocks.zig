const mmio = @import("mmio.zig");

pub fn initClocks() void {
    mmio.xosc.ctrl = 0xAA0;
    mmio.xosc.startup = 47;

    mmio.xosc_set.ctrl = 0x00fab000;

    while ((mmio.xosc.status & (1 << 31)) == 0) {}

    mmio.clocks.clk_ref_ctrl = 0x2;
    mmio.clocks.clk_sys_ctrl = 0x0;

    mmio.resets_clr.reset = 1 << 12;
    while ((mmio.resets.reset_done & (1 << 12)) == 0) {}

    mmio.pll_sys.fbdiv_int = 125;
    mmio.pll_sys.prim = 0x62 << 12;

    mmio.pll_sys_clr.pwr = 0x21;

    while ((mmio.pll_sys.cs & (1 << 31)) == 0) {}

    mmio.pll_sys_clr.pwr = 1 << 3;

    mmio.clocks.clk_sys_ctrl = 0x1;

    mmio.clocks.clk_peri_ctrl = (1 << 11) | (0x1 << 5);
}
