# 12 - Clocks

When I was getting the systick isr setup in the scheduler, I noticed it was wayyy slower than before. Now that we aren't using the pico-sdk, we need to manually setup the clocks.

During boot up there is a ring oscillator that is used which runs at ~6MHz. This is a lower power option, but is slow and not a stable frequency (section `2.15.2.1` of the datasheet states that the frequency is likely to be in the range 4-8MHz and is guaranteed to be in the range 1.8-12MHz).

There is a crystal oscillator (XOSC) that is driven by an external crystal, and the pi pico has a 12MHz crystal. This is distributed to phase-locked loops (PLLs) that can multiply the XOSC frequency for higher clock speeds. The datasheet (`2.16.1`) mentions a max clock speed of 133MHz, but apparently that has been bumped up to 200MHz.

