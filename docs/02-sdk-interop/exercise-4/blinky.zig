extern fn gpio_init(gpio: u32) void;
extern fn gpio_set_dir(gpio: u32, out: bool) void;
extern fn gpio_put(gpio: u32, value: bool) void;
extern fn sleep_ms(ms: u32) void;

const LED_PIN = 25;

export fn main() noreturn {
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, true);

    while (true) {
        gpio_put(LED_PIN, true);
        sleep_ms(1000);
        gpio_put(LED_PIN, false);
        sleep_ms(1000);
    }
}
