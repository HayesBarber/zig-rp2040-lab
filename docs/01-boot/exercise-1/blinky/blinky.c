#include "pico/stdlib.h"
#include "pico/cyw43_arch.h"

#define LED_DELAY_MS 200

int pico_led_init(void) { 
  return cyw43_arch_init();
}

void pico_set_led(int led_on) {
  cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, led_on);
}

int main() {
  pico_led_init();
  while (true) {
    pico_set_led(1);
    sleep_ms(LED_DELAY_MS);
    pico_set_led(0);
    sleep_ms(LED_DELAY_MS);
  }
}

