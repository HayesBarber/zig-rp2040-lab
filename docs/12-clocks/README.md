# 12 - Clocks

When I was getting the systick isr setup in the scheduler, I noticed it was wayyy slower than before. Now that we aren't using the pico-sdk, we need to manually setup the clocks.

During boot up there is a ring oscillator that is used which runs at ~6MHz. This is a lower power option, but is slow and not a stable frequency (section `2.15.2.1` of the datasheet states that the frequency is likely to be in the range 4-8MHz and is guaranteed to be in the range 1.8-12MHz).

There is a crystal oscillator (XOSC) that is driven by an external crystal, and the pi pico has a 12MHz crystal. This is distributed to 2 phase-locked loops (PLLs) that can multiply the XOSC frequency for higher clock speeds. The datasheet (`2.16.1`) mentions a max clock speed of 133MHz, but apparently that has been bumped up to 200MHz. The PLLs are `pll_sys` and `pll_usb` used for system clock and USB respectively.

The XOSC is not enabled on startup. To do so, there is a `CTRL_ENABLE` register to set. Additionally, there is `STARTUP_DELAY` and `STARTUP_STABLE` timer registers to allow the XOSC to build up amplitude. `STARTUP_DELAY` specifies how many cycles must be seen before use, and is a multiple of 256. `STARTUP_STABLE` is a flag to indicate XOSC can be used, and the programmer would likely poll this. XOSC registers start at a base address of `0x40024000`.

The reference clock (`clk_ref`) and system clock (`clk_sys`) are the primary things that we need to set up to point the the higher clock sources. Clock registers start at `0x40008000`. `clk_ref` and `clk_sys` have glitchless multiplexers to switch between clock sources.

## Clock Init Sequence

For this project, I would like to get both the PLLs setup for a system clock of 125MHz and 48MHz for USB. The sequence to do this is as follows:

1. Setup XOSC
  - `CTRL` register is address `0x40024000` (which is also the base of XOSC)
  - Load value `0XAA0` into the CTRL register to set frequency range of 1-15MHz
  - Load startup delay value of `47` into `STARTUP` register (offset 0x0c from XOSC base) based on the datasheet section `2.16.3`
2. Start XOSC
  - Use the atomic register address (`0x40026000`) to enable the XOSC by writing value `0x00fab000`
3. Wait for XOSC
  - Poll the `STATUS` register (offset 0x04 from XOSC base) bit 31 and wait for stable (bit value of 1)
4. Switch clock source to XOSC
  - Use `CLK_REF_CTRL` register (offset 0x30 from clocks base) and write value of 0x2 (XOSC source)
  - Use `CLK_SYS_CTRL` register (offset 0x3c from clocks base) and write value of 0x0 (ref clock for system clock aka XOSC)
5. Setup PLL
  - Bring `PLL_SYS` out of reset writing a 0 to `RESET` register bit 12 (offset 0x0 from reset base of `0x4000c000`)
    - Bit 12 is `PLL_SYS`
    - Will use atomic bitmask clear (`addr + 0x3000`) which will be `0x4000f000` in this case
  - Wait for `PLL_SYS` to be out of reset by polling `RESET_DONE` register bit 12 for a 1 (offset 0x8 from base)
  - Write a value of 125 to the `FBDIV_INT` register (offset 0x8 from `PLL_SYS` base of `0x40028000`)
    - See datasheet `2.18.2.1`, but we need `FBDIV=125, PD1=6, PD2=2` for a 125MHz system clock with a 12MHz input
  - Write 0x62 to bits 14:12 of the `PRIM` register (offset 0xc from `PLL_SYS` base)
  - Power up the PLL by writing 0x21 to `PWR` register (offset 0x4 from `PLL_SYS` base)
    - Use atomic clear `0x4002b000`
    - 0x21 is for bits 5 and 0, which powers up PLL VCO and PLL respectively
  - Wait for the PLL to lock by polling bit 31 of the `CS` register (offset 0x0 from `PLL_SYS`)
  - Clear POSTDIVPD bit in the `PWR` register to enable PLL dividers
    - Write 0x08 to atomic clear register `0x4002b000` to clar bit 3
6. Switch system clock to PLL
  - Write a 1 to `CLK_SYS_CTRL` (offset 0x3c from clock base) to change clock source to `CLKSRC_CLK_SYS_AUX`
    - `CLKSRC_PLL_SYS` is the default aux source

## References

- https://www.youtube.com/watch?v=sBsCWpqmQfA
- https://github.com/LifeWithDavid/RaspberryPiPico-BareMetalAdventures/tree/da74b8b287265fcfcd1437314aa470df22944f58/Chapter%2005

