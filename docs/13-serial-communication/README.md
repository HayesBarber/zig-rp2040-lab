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

The RP2040 has 2 identical UART peripherals: UART0 and UART1. My understanding is that the initialization is the same, just different addresses. We will plan on using UART0. The sequence for setting it up is as follows:

1. Configure `clk_peri` to use `clk_sys`
  - Within `CLK_PERI_CTRL` register, set bit 11 to enable, and AUXSRC bits (7:5) to `CLKSRC_PLL_SYS` (0x1)
2. Bring UART0 out of reset
  - Use atomic address to clear `RESET` bit 22 for UART0
  - Poll `RESET_DONE` bit 22 for a 1 to ensure reset is done
3. Configure GPIO pins 0 and 1 for use with UART
  - Bring IOBank0 out of reset by using atomic clear on `RESET` register bit 5
  - Poll `RESET_DONE` bit 5 for a 1 to ensure reset is done
  - Enable function 2 (UART TX and RX per `2.19.2`) in `GPIO0_CTRL` and `GPIO1_CTRL` (offsets 0x4 and 0xc from IOBank0 registers at `0x40014000`)
4. Disable UART so we can configure it
  - Since we are using UART0, base address of registers is `0x40034000`
  - `UARTCR` is the control register at offset 0x30, write a 0 to it
5. Configure baud rate
  - Per `4.2.7.1` for a baud rate of 115200 and UARTCLK = 125MHz
  - BRDI=67 and BRDF=52
  - Store 67 in `UARTIBRD` (offset 0x24 from UART0 base)
  - Store 52 in `UARTFBRD` (offset 0x28 from UART0 base)
6. Set word length and enable FIFOs
  - Use `UARTLCR_H` register (offset  0x2c from UART0 base) to set bits 4, 5, and 6
  - Bit 4 enableds FIFOs
  - Bits 6:5 sets word length to 8
7. Enable UART
  - Use `UARTCR` again but now set bits 0, 8, and 9
  - Bit 0 enables UART
  - Bit 8 enables transmit
  - Bit 9 enables recieve
8. Send data
  - The `UARTDR` register (offset 0x0 from UART0 base) is the data register
  - Bits 7:0 are the data bits to read and write
  - To send data, first check if the TX FIFO is full by reading bit 5 of `UARTFR` register (offset 0x18 from UART0 base)
    - If 1, FIFO is full so loop back
    - If 0, then we can write to the data register
  - Start and stop bits are handled automatically
9. Recieve data
  - Read bit 4 of `UARTFR`
    - If 1, FIFO is empty (no data)
    - If 0, read data from `UARTDR`

## References

- https://youtu.be/MUT6ZubKS3w?si=CVum4dLJZ9pARr3v
- https://github.com/LifeWithDavid/RaspberryPiPico-BareMetalAdventures/tree/main/Chapter%2003

