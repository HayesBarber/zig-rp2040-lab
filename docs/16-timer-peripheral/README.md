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

## Watchdog

As mentioned above, the watchdog timer needs to be running for the timer peripheral to start counting, so lets look into that. Watchdog is section `4.7` of the datasheet.

The idea of a watchdog timer is that is counts down to 0, and restarts stuff if it reaches zero. This is essentially a safety mechanism to help the program from getting stuck in a bad state. The program needs to periodically write a value to the watchdog to prevent it from reaching 0.

The reason this needs to be running for the timer peripheral is because this tick is distrubted to the timer. The watchdog reference (`clk_tick`) is driven by `clk_ref`.

There is a note in `4.7.3` that informs that, due to a logic error, the watchdog counter is decremented twice per tick, and that the program should double the intended count down value.

The sequence for enabling and writing to the watchdog is as follows:

- Use `TICK` register to enable tick generation (bit 9) and configure cycles (bits 8:0)
  - "Cycles" bits are essentially a divider to get a 1 microsecond value
  - Since `clk_tick` is driven from `clk_ref`, and we the 12MHz XOSC for `clk_ref`, we will use a value of 12 for this
  - Cycles is number of `clk_tick` cycles that need to occur for the watchdog to tick itself
  - [pico-sdk reference](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/hardware_watchdog/include/hardware/watchdog.h#L59)
- Choose which systems reset on watchdog reaching 0 using `WDSEL` register
  - The datasheet shows an example of resetting everything except ROSC and XOSC (set all bits but 0 and 1)
  - `WDSEL` is in PSM registers located at `0x40010000` offset 0x8
- Use `LOAD` register to load an intial value
  - Remember to double
  - Or just use `0xffffff` for max value
- Use `CTRL` register to enable watchdog (bit 30)
- Periodically reload using `LOAD`
  - SysTick could do it?

Watchdog registers start at `0x40058000`:

- `CTRL`
- `LOAD`
- `REASON`
- `SCRATCH0:7`
- `TICK`

## Pre-implementation

Implementation goals:

- Core module:
  - Provide APIs for mmio of timer and watchdog
  - Provide timer APIs (microseconds/milliseconds since boot)
- zrt0 module:
  - Configure watchdog, but do not start it
- Kernel module:
  - Enable watchdog
  - Feed wathdog during systick
    - Consider performance impact of doing it _every_ SysTick
  - Disable watchdog in hard-fault ISR to preserve rapid blinking LED

