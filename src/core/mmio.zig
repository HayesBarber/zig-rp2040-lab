pub const CORTEX_BASE = 0xe0000000;
pub const SYSTICK_BASE = CORTEX_BASE + 0xe010;

pub fn putAddr(addr: u32, value: u32) void {
    @as(*volatile u32, @ptrFromInt(addr)).* = value;
}

pub fn getAddr(addr: u32) u32 {
    return @as(*volatile u32, @ptrFromInt(addr)).*;
}

fn mmio(comptime T: type, addr: u32) *volatile T {
    return @ptrFromInt(addr);
}

const SysTick = extern struct {
    csr: u32,
    rvr: u32,
    cvr: u32,
    calib: u32,
};

pub const systick = mmio(SysTick, SYSTICK_BASE);
