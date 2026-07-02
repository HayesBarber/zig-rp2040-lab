pub const GPIO_OUT_XOR = 0xd000001c;
pub const LED_PIN = 25;
pub const SIO_BASE = 0xd0000000;
pub const SPINLOCK_0: u32 = SIO_BASE + 0x100;

pub extern fn printf(fmt: [*:0]const u8, ...) void;

pub extern fn stdio_init_all() void;

pub extern fn sleep_ms(ms: u32) void;

pub extern fn sleep_us(us: u32) void;

pub extern fn clock_get_hz(clk_index: c_int) u32;

pub extern fn multicore_launch_core1(entry: *const fn () callconv(.c) void) void;

pub fn put32(addr: u32, value: u32) void {
    @as(*volatile u32, @ptrFromInt(addr)).* = value;
}

pub fn get32(addr: u32) u32 {
    return @as(*volatile u32, @ptrFromInt(addr)).*;
}

pub fn toggleGPIO(comptime pin: u8) void {
    const mask = 1 << pin;
    put32(GPIO_OUT_XOR, mask);
}

pub fn toggleLED() void {
    toggleGPIO(LED_PIN);
}

pub fn ledInit() void {
    // IO BANK
    put32(0x4000f000, (1 << 5));
    // Reset done?
    while ((get32(0x4000c008) & (1 << 5)) == 0) {}
    // IO PAD = FUNC 5 (GPIO)
    put32(0x400140cc, 0x05);
    // GPIO_OE
    put32(0xd0000020, (1 << 25));
}

pub fn spinlockGet(comptime num: u8) void {
    comptime {
        if (num > 31) {
            @compileError("There are only 32 spinlocks on the RP2040");
        }
    }
    const address: u32 = SPINLOCK_0 + (num * 0x4);
    while (get32(address) == 0) {}
}

pub fn spinlockFree(comptime num: u8) void {
    comptime {
        if (num > 31) {
            @compileError("There are only 32 spinlocks on the RP2040");
        }
    }
    const address: u32 = SPINLOCK_0 + (num * 0x4);
    put32(address, 1);
}
