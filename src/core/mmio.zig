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
