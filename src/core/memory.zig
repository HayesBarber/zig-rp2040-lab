pub const CORTEX_BASE = 0xe0000000;
pub const CORTEX_SYST_CSR = CORTEX_BASE + 0xe010;
pub const CORTEX_SYST_RVR = CORTEX_BASE + 0xe014;

pub fn putAddr(addr: u32, value: u32) void {
    @as(*volatile u32, @ptrFromInt(addr)).* = value;
}

pub fn getAddr(addr: u32) u32 {
    return @as(*volatile u32, @ptrFromInt(addr)).*;
}
