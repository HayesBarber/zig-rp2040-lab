# 10 - crt0

Similar to the last chapter on linker scripts, we have interacted with crt0 previously, but I would like a deeper dive. 

## What is crt0?

crt0 is short for "C runtime 0", and is a startup routine that occurs before your `main()` function. Things like zeroing .bss, initialising .data, parsing command line args, and so on happen in crt0.

## Pico SDK crt0

For the pico-sdk, crt0 is written in assembly, and can be found [here](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/pico_crt0/crt0.S). This chapter will mainly focus on this implementation.

- One of the first things in the crt0 file (after all the initial `#include`s and `#define`s) is the [vector table](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/pico_crt0/crt0.S#L59).
  - The first two entries of this table are the top of the stack, and the reset handler
  - The next entries are the interrupt service routines (isr)
    - ends at line 93
  - Next is interrupt requests
    - ends at 189
  - lines 191-232 define some macros that create weak links for ISRs that can be overriden
    - you can see on line 348-352 some ISRs defaulting to breakpoints
- lines 358-378 contain the binary info header
- line 399 defines `_entry_point`. It technically prefaces the reset handler, and is the ELF entry point. If debugging the rp2040, `_entry_point` will ensure the boot sequence occured properly and initialised flash
- line 465 starts getting into the reset handler
  - Ensures that only core 0 continues (sends core 1 to ROM to wait for core 0 to start it)
  - Copy .data
  - Clear .bss
  - line 547 we can see the `platform_entry`
- The remainder of crt0 is largely supporting startup
  - Defining `data_cpy_table`
  - A weak `runtime_init` that can be overriden
  - `.stack` and `.heap` sections

