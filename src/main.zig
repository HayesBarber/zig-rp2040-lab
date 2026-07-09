const core = @import("core");

comptime {
    @import("zrt0").init();
}

pub const GPIO_OUT_XOR = 0xd000001c;
pub const LED_PIN = 25;

pub fn putAddr(addr: u32, value: u32) void {
    @as(*volatile u32, @ptrFromInt(addr)).* = value;
}

pub fn getAddr(addr: u32) u32 {
    return @as(*volatile u32, @ptrFromInt(addr)).*;
}

pub fn toggleGPIO(comptime pin: u8) void {
    const mask = 1 << pin;
    putAddr(GPIO_OUT_XOR, mask);
}

pub fn toggleLED() void {
    toggleGPIO(LED_PIN);
}

pub fn ledInit() void {
    // IO BANK
    putAddr(0x4000f000, (1 << 5));
    // Reset done?
    while ((getAddr(0x4000c008) & (1 << 5)) == 0) {}
    // IO PAD = FUNC 5 (GPIO)
    putAddr(0x400140cc, 0x05);
    // GPIO_OE
    putAddr(0xd0000020, (1 << 25));
}

pub fn main() noreturn {
    ledInit();
    while (true) {
        toggleLED();
        var a: u32 = 150000;
        while (a > 0) : (a -= 1) {
            asm volatile ("nop");
        }
    }
}
