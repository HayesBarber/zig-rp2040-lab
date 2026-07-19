# 16 - Timer Peripheral

In chapter 04 we covered timer interrupts, and landed on using SysTick to drive the context switch. We did mention that other timer peripherals exist, and this chapter will focus on the RP2040's timer peripheral as described in section `4.6`.

While SysTick will continue to drive the context switch, I would like to see if the timer peripheral is viable to use for measuring latency. Even if it ends up not being precise enough, I don't think this will be a waste of time to learn!

## Overview

The timer peripheral is a 64-bit global monotonic microsecond timer. Being microsecond precision puts it at 1MHz. The datasheet descibes that, practically speaking, the timer won't overflow with a 64-bit counter at 1MHz taking thousands of years to hit capacity.

With the timer being 64-bit, it needs to be broken up into it's upper and lower 32 bits. The are two pairs of registers to read/write respectively: `TIMEHR`/`TIMELR` and `TIMEHW`/`TIMELW`. I think these are read as "Time High Read" / "Time Low Read" etc. It seems the intended use is to read the lower register before the high, and utilizes a latching mechanism.

Per section `4.6.1`, the watchdog tick must be running for the timer to start counting. We are not currently using that, so will need to set it up.

In order to read the time, one could read `TIMELR` followed by `TIMEHR`. Recall the latching mechanism, so this operation is not multi-core safe. The datasheet provides an example from the pico-sdk that _is_ multi-core safe and instead uses the `TIMERAWH`/`TIMERAWL` registers which do not latch.

Timer registers start at `0x40054000`:

- `TIMEHW`
- `TIMELW`
- `TIMEHR`
- `TIMELR`
- `ALARM0:3`
- `ARMED`
- `TIMERAWH`
- `TIMERAWL`
- `DBGPAUSE`
- `PAUSE`
- `INTR`
- `INTE`
- `INTF`
- `INTS`

