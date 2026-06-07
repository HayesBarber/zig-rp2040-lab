export fn main() linksection(".boot.entry") noreturn {
    const PUT32 = struct {
        fn write(addr: u32, value: u32) void {
            @as(*volatile u32, @ptrFromInt(addr)).* = value;
        }
    };

    const GET32 = struct {
        fn read(addr: u32) u32 {
            return @as(*volatile u32, @ptrFromInt(addr)).*;
        }
    };

    // IO BANK
    PUT32.write(0x4000f000, (1 << 5));

    // Reset done?
    while ((GET32.read(0x4000c008) & (1 << 5)) == 0) {}

    // IO PAD = FUNC 5 (GPIO)
    PUT32.write(0x400140cc, 0x05);

    // GPIO_OE
    PUT32.write(0xd0000020, (1 << 25));

    while (true) {
        // XOR GPIO
        PUT32.write(0xd000001c, (1 << 25));

        var a: u32 = 20000;
        while (a > 0) : (a -= 1) {}
    }
}
