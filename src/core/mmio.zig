pub fn putAddr(addr: u32, value: u32) void {
    @as(*volatile u32, @ptrFromInt(addr)).* = value;
}

pub fn getAddr(addr: u32) u32 {
    return @as(*volatile u32, @ptrFromInt(addr)).*;
}

fn mmio(comptime T: type, addr: u32) *volatile T {
    return @ptrFromInt(addr);
}

const CORTEX_BASE = 0xe0000000;
const SYSTICK_BASE = CORTEX_BASE + 0xe010;
const SysTick = extern struct {
    csr: u32,
    rvr: u32,
    cvr: u32,
    calib: u32,
};
pub const systick = mmio(SysTick, SYSTICK_BASE);

const GPIO_BASE = 0xd0000014;
const GPIO = extern struct {
    set: u32,
    clear: u32,
    xor: u32,
};
pub const gpio = mmio(GPIO, GPIO_BASE);

const XOSC_BASE = 0x40024000;
const XoscRegs = extern struct {
    ctrl: u32,
    status: u32,
    dormant: u32,
    startup: u32,
};
pub const xosc = mmio(XoscRegs, XOSC_BASE);
pub const xosc_set = mmio(XoscRegs, XOSC_BASE + 0x2000);

const CLOCKS_BASE = 0x40008000;
const ClocksRegs = extern struct {
    _pad0: [12]u32,
    clk_ref_ctrl: u32,
    clk_ref_div: u32,
    clk_ref_selected: u32,
    clk_sys_ctrl: u32,
};
pub const clocks = mmio(ClocksRegs, CLOCKS_BASE);

const RESETS_BASE = 0x4000c000;
const ResetsRegs = extern struct {
    reset: u32,
    _pad0: u32,
    reset_done: u32,
};
pub const resets = mmio(ResetsRegs, RESETS_BASE);
pub const resets_clr = mmio(ResetsRegs, RESETS_BASE + 0x3000);

const PLL_SYS_BASE = 0x40028000;
const PllSysRegs = extern struct {
    cs: u32,
    pwr: u32,
    fbdiv_int: u32,
    prim: u32,
};
pub const pll_sys = mmio(PllSysRegs, PLL_SYS_BASE);
pub const pll_sys_clr = mmio(PllSysRegs, PLL_SYS_BASE + 0x3000);
