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

Another question that comes to mind is how does MicroZig handle USB communication? It seems that it has some sort of [usb.zig](https://github.com/ZigEmbeddedGroup/microzig/blob/main/port/raspberrypi/rp2xxx/src/hal/usb.zig) implementation. It is ~500 LOC, and I am not sure how portable it would be. Will revisit this if it comes to it.

## TinyUSB Integration

