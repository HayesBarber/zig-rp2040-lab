extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn stdio_init_all() void;
extern fn sleep_ms(ms: u32) void;

export fn main() noreturn {
    stdio_init_all();

    while (true) {
        _ = printf("Hello, world!\n");
        sleep_ms(1000);
    }
}
