const memory = @import("memory.zig");

pub const GPIO_OUT_SET = 0xd0000014;
pub const GPIO_OUT_CLEAR = 0xd0000018;
pub const GPIO_OUT_XOR = 0xd000001c;
pub const LED_PIN = 25;

pub fn toggleGPIO(comptime pin: u8) void {
    const mask = 1 << pin;
    memory.putAddr(GPIO_OUT_XOR, mask);
}

pub fn setGPIO(comptime pin: u8) void {
    const mask = 1 << pin;
    memory.putAddr(GPIO_OUT_SET, mask);
}

pub fn clearGPIO(comptime pin: u8) void {
    const mask = 1 << pin;
    memory.putAddr(GPIO_OUT_CLEAR, mask);
}

pub fn toggleLED() void {
    toggleGPIO(LED_PIN);
}

pub fn turnOnLED() void {
    setGPIO(LED_PIN);
}

pub fn turnOffLED() void {
    clearGPIO(LED_PIN);
}

pub fn ledInit() void {
    // IO BANK
    memory.putAddr(0x4000f000, (1 << 5));
    // Reset done?
    while ((memory.getAddr(0x4000c008) & (1 << 5)) == 0) {}
    // IO PAD = FUNC 5 (GPIO)
    memory.putAddr(0x400140cc, 0x05);
    // GPIO_OE
    memory.putAddr(0xd0000020, (1 << 25));
}
