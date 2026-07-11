# 12 - Clocks

When I was getting the systick isr setup in the scheduler, I noticed it was wayyy slower than before. Now that we aren't using the pico-sdk, we need to manually setup the clocks.

During boot up there is a ring oscillator that is used which runs at ~6MHz. This is a lower power option, but is slow and not a stable frequency (section `2.15.2.1` of the datasheet states that the frequency is likely to be in the range 4-8MHz and is guaranteed to be in the range 1.8-12MHz).

There is a crystal oscillator (XOSC) that is driven by an external crystal, and the pi pico has a 12MHz crystal. This is distributed to 2 phase-locked loops (PLLs) that can multiply the XOSC frequency for higher clock speeds. The datasheet (`2.16.1`) mentions a max clock speed of 133MHz, but apparently that has been bumped up to 200MHz. The PLLs are `pll_sys` and `pll_usb` used for system clock and USB respectively.

The XOSC is not enabled on startup. To do so, there is a `CTRL_ENABLE` register to set. Additionally, there is `STARTUP_DELAY` and `STARTUP_STABLE` timer registers to allow the XOSC to build up amplitude. `STARTUP_DELAY` specifies how many cycles must be seen before use, and is a multiple of 256. `STARTUP_STABLE` is a flag to indicate XOSC can be used, and the programmer would likely poll this. XOSC registers start at a base address of `0x40024000`.

The reference clock (`clk_ref`) and system clock (`clk_sys`) are the primary things that we need to set up to point the the higher clock sources. Clock registers start at `0x40008000`. `clk_ref` and `clk_sys` have glitchless multiplexers to switch between clock sources.

## Clock Init Sequence

For this project, I would like to get both the PLLs setup for a system clock of 125MHz and 48MHz for USB. The sequence to do this is as follows:

- todo

## References

- https://www.youtube.com/watch?v=sBsCWpqmQfA

