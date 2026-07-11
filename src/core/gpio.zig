const mmio = @import("mmio.zig");

pub const LED_PIN = 25;

pub fn toggleGPIO(comptime pin: u8) void {
    const mask = 1 << pin;
    mmio.gpio.xor = mask;
}

pub fn setGPIO(comptime pin: u8) void {
    const mask = 1 << pin;
    mmio.gpio.set = mask;
}

pub fn clearGPIO(comptime pin: u8) void {
    const mask = 1 << pin;
    mmio.gpio.clear = mask;
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
    mmio.putAddr(0x4000f000, (1 << 5));
    // Reset done?
    while ((mmio.getAddr(0x4000c008) & (1 << 5)) == 0) {}
    // IO PAD = FUNC 5 (GPIO)
    mmio.putAddr(0x400140cc, 0x05);
    // GPIO_OE
    mmio.putAddr(0xd0000020, (1 << 25));
}
