pub const GPIO_OUT_XOR = 0xd000001c;
pub const CORTEX_BASE = 0xe0000000;
pub const CORTEX_SYST_CSR = CORTEX_BASE + 0xe010;
pub const CORTEX_SYST_RVR = CORTEX_BASE + 0xe014;
pub const LED_PIN = 25;
pub const SYSTICK_RELOAD_VALUE = 125000 - 1; // 1 ms
pub const SYSTICK_ENABLE_BITMASK = 0x7;
pub const SYSTICK_DISABLE_BITMASK = 0x0;
pub var TICK_COUNTER: u32 = 0;

pub extern fn printf(fmt: [*:0]const u8, ...) void;

pub extern fn stdio_init_all() void;

pub extern fn sleep_ms(ms: u32) void;

pub extern fn clock_get_hz(clk_index: c_int) u32;

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

pub fn initSystick() void {
    put32(CORTEX_SYST_RVR, SYSTICK_RELOAD_VALUE);
    put32(CORTEX_SYST_CSR, SYSTICK_ENABLE_BITMASK);
}

//Rewrite of weak systick IRQ in crt0.s file
export fn isr_systick() void {
    TICK_COUNTER += 1;
    if (TICK_COUNTER == 1000) {
        TICK_COUNTER = 0;
        const clk_sys = 5; // clk_sys enum value in SDK
        printf("clk_sys = %lu\n", clock_get_hz(clk_sys));
        printf("RVR = %lu\n", get32(CORTEX_SYST_RVR));
        toggleLED();
    }
}
