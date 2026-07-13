# 13 - Serial Communication

One way or another we are going to need to be able to implement some sort of `print` functionality for the pico to send data to a connected computer. The little bit of research I have done so far yeilded a reality that USB is extremely complicated. Implementing it myself bare-metal style may take way too long, and would dominate this project. Being as how my main goals for this project are centered around CPU scheduling, I am thinking we need to come up with an alternative. Here are some ideas:

1. Use UART instead, and use a UART-to-USB adapter
  - UART is feasible to implement myself
  - Adapter handles USB
2. Integrate [tinyusb](https://github.com/hathach/tinyusb)
  - No adapter needed
  - C library, so might now be easy to integrate
3. Wire up a display to the pico, and use that as the console for output
  - Again, could use a simpler protocal
  - Data doesn't end up on the connected computer

If tinyusb isn't a pain to integrate with, it would probably be the cleanest option. My second choice would then be the UART-to-USB adater. An external display is my least favorite.

## MicroZig?

Another question that comes to mind is how does MicroZig handle USB communication? It seems that it has some sort of [usb.zig](https://github.com/ZigEmbeddedGroup/microzig/blob/main/port/raspberrypi/rp2xxx/src/hal/usb.zig) implementation. It is ~500 LOC, and I am not sure how portable it would be. Will revisit this if it comes to it.

## TinyUSB Integration

It seems that tinyusb may actually [depend on the pico-sdk](https://github.com/hathach/tinyusb/blob/master/src/portable/raspberrypi/rp2040/rp2040_usb.h). This makes me lean towards the UART option.

## UART-to-USB

I have purchased a UART-to-USB adapter ([this one](https://www.amazon.com/dp/B0FJRTL572?th=1)), and am planning on going that route. While I was ordering stuff, I also ordered some more RP2040 boards that have two conveniences I desired: USB-C and a reset button.

The RP2040 has 2 identical UART peripherals: UART0 and UART1. My understanding is that the initialization is the same, just different address. We will plan on using UART0. The sequence for setting it up is as follows:

1. Configure `clk_peri` to use `clk_sys`
  - Within `CLK_PERI_CTRL` register, set bit 11 to enable, and AUXSRC bits to `CLKSRC_PLL_SYS`
2. Bring UART0 out of reset
  - Use atomic address to clear `RESET` bit 22 for UART0
  - Poll `RESET_DONE` bit 22 for a 1 to ensure reset is done

## References

- https://youtu.be/MUT6ZubKS3w?si=CVum4dLJZ9pARr3v
- https://github.com/LifeWithDavid/RaspberryPiPico-BareMetalAdventures/tree/main/Chapter%2003

