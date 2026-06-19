# 04 - Timer Interrupts

Naturally a scheduler is going to need to define an interrupt handler so that it can preempt tasks and perform context switches.

## Exercise 7: Blinky interrupt

The goal will be to blink the onboard LED on a timer interrupt loop. Something like:

1. Register timer interrupt
2. Interrupt fires -> blink
3. Re-register timer interrupt

### Systick or hardware timer?

There are a few options for interrupt sources, namely using a systick or a hardware peripheral timer.

A systick is essentially built into the Cortex-M0+ itself, while a hardware peripheral would be vendor specific. From what I can tell, it doesn't necessarily matter as they both could serve as the interrupt source. The systick seems to be simpler, so I am leaning towards that.

The pico sdk has a `add_alarm_in_ms` function, but it's `static inline` and I don't really want dig through the implementation and map the signatures/structs. I think I will go bare metal for this and use [systick_isr example](https://github.com/carlosftm/RPi-Pico-Baremetal/blob/main/04_systick_isr/systick_isr.c) as my reference.

### How to setup the systick and register the ISR?

For this to work, I will need to register an ISR (interrupt service routine, aka interrupt handler) with the systick to fire on some interval.

The exception number of systick is 15, and the ISR is defined in [crt0](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/pico_crt0/crt0.S#L77-L77). According to [this github thread](https://github.com/raspberrypi/pico-examples/issues/532), it can be overriden ([example](https://github.com/Blimp01/pico_non_blocking_timer/blob/master/non_blocking_timer.c#L16)).

I may also be able to use [exception_set_exclusive_handler](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/hardware_exception/include/hardware/exception.h#L136-L136) from the pico sdk, which may be easier to define as `extern` in zig.

---

There are two pieces of code to call out from the [bare metal example](https://github.com/carlosftm/RPi-Pico-Baremetal/blob/main/04_systick_isr/systick_isr.c#L117) and [non-blocking timer example](https://github.com/Blimp01/pico_non_blocking_timer/blob/master/example/non_blocking_timer.c#L8) that are effectively doing the same thing with the systick initialization.

```c
// systick_isr.c
#define CORTEX_BASE 0xe0000000UL
#define CORTEX_SYST_CSR (CORTEX_BASE + 0xe010)
#define CORTEX_SYST_RVR (CORTEX_BASE + 0xe014)
#define COUNT (12000000 / 32)                                    // with XOSC (12MHZ), 12,000,000 ticks = 1 second.
PUT32( CORTEX_SYST_RVR, COUNT );                                 // start counting down from COUNT(12,000,000/16 ticks)
PUT32( CORTEX_SYST_CSR, ( 1 << 2 ) | ( 1 << 1 ) | ( 1 << 0 ) );  // source clock external / enable tick int / enable
```

```c
//non_blocking_timer.c
void init_systick()
{ 
	systick_hw->csr = 0; 	      //Disable
	systick_hw->rvr = 124999UL; //Standard System clock (125Mhz)/ (rvr value + 1) = 1ms
  systick_hw->csr = 0x7;      //Enable Systic, Enable Exceptions
}
```

Both of these code snippets are manipulating the ARM Cortex-M0+ registers (starts at base `0xe0000000`) to set the systick countdown value, and enable the counter/exception/clock source. Details can be found in the RP2040 datasheet (page 77) and [systick.h of the pico-sdk](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2040/hardware_structs/include/hardware/structs/systick.h#L27-L27) Lets break it down.

#### `SYST_CSR` Register

`SYST_CSR` uses 4 bit locations: `0`, `1`, `2`, and `16`. 

- `Bit 0`: Enables (1) and disables (0) the systick counter
- `Bit 1`: Exception request enabled (1) or disabled (0)
	- aka enable/disable the ISR
- `Bit 2`: Systick clock source. Processor clock (1) or external reference (0)
- `Bit 16`: 1 if timer counted to 0 the last time this bit was read

For initialization, bits `0`, `1`, and `2` are being set by the code snippets above. The `systick_isr.c` example is using bit shifts, while the `non_blocking_timer.c` example is setting to `0x7` (which is `0b111`).

> Note that for `systick_isr.c` the comment about `source clock external` seems to be incorrect (or at least misleading). Bit 2 is being set to 1 which means processor clock.

> The code in `non_blocking_timer` is disabling before setting values. I am not sure if this is necessary.


#### `SYST_RVR` Register

`SYST_RVR` is a value between `0` and `0x00FFFFFF` (bits 23:0) that sets the value to count down from, as well as reseting to this value when the counter reaches 0.

This value is counts down based on the clock cycle reference, and includes 0. So if you want the ISR to fire every N cycles, you would set `SYST_RVR` to N-1.

The examples above are using different clock speed references. `systick_isr.c` is using a 12MHz reference versus a 125MHz reference in `non_blocking_timer.c`. As such, the `SYST_RVR` being set is based on the caclulation of clock speed to how often the interrupt should fire (1 second vs 1 millisecond).

Why is it 24 bits? From a quick search it seems to be for efficiency purposes.

---

The `main.zig` file is straightforward. Initialize stdio, the LED, and systick before looping forever.

`pico.zig` contains the meat of this exercise. The two main functions for systick are `initSystick` and `isr_systick`. As mentioned above, we setup the `SYST_RVR` and `SYST_CSR` registers via their memory locations and bitmasks. And then `isr_systick` is exported to override the weak link defined in the pico sdk (the same way it's done in [the example](https://github.com/Blimp01/pico_non_blocking_timer/blob/master/example/non_blocking_timer.c#L15)).

Note how the systick ISR does not need to re-register the counter (it is multi-shot).

I ran into two intersting scenarios:

1. I initially forgot to export `isr_systick`
	- This caused the program to hang. The reason being becuase the default ISR for systick is defined [as a breakpoint](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/pico_crt0/crt0.S#L336-L336). So either I had the debugger hooked up and it was stopping there, or there was no debugger which probably leads to a fault of some sort.
2. The LED was blinking faster than 1 second intervals
	- Since the system clock is 125MHz, I figured that setting `SYST_RVR` to 125,000,000 made since as that would result in a 1 second interval. While that may be true, remember that `SYST_RVR` is a ___24 bit number___. 125 million is a 27 bit number, so the upper bits were likely disgarded leading to a faster blink rate.
	- The fix? Use a 1ms interval and increment a counter. When that counter == 1000, blink.


