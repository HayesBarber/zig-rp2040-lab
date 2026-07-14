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

pub fn resetIOBank0() void {
    mmio.resets_clr.reset = 1 << 5;
    while ((mmio.resets.reset_done & (1 << 5)) == 0) {}
}

pub fn ledInit() void {
    mmio.iobank0.gpio[25].ctrl = 0x05;
    mmio.putAddr(0xd0000020, (1 << 25));
}
