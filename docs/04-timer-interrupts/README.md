# 04 - Timer Interrupts

Naturally a scheduler is going to need to define an interrupt handler so that it can preempt tasks and perform context switches.

## Exercise 7: Blinky interrupt

The goal will be to blink the onboard LED on a timer interrupt loop. Something like:

1. Register timer interrupt
2. Interrupt fires -> blink
3. Re-register timer interrupt

### Systick or hardware timer?

There is a few options for interrupt sources, namely using a systick or a hardware peripheral timer.

A systick is essentially built into the Cortex-M0+ itself, while a hardware peripheral would be vendor specific. From what I can tell, it doesn't necessarily matter as they both could serve as the interrupt source. The systick seems to be simpler, so I am leaning towards that.

The pico sdk has a `add_alarm_in_ms` function, but it's `static inline` and I don't really want dig through the implementation and map the signatures/structs. I think I will go bare metal for this and use [systick_isr example](https://github.com/carlosftm/RPi-Pico-Baremetal/blob/main/04_systick_isr/systick_isr.c) as my reference.

### How to setup the systick and register the ISR?

For this to work, I will need to register an ISR (interrupt service routine, aka interrupt handler) with the systick to fire on some interval.

The interrupt/exception number of systick is 15, and the ISR is defined in [crt0](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/pico_crt0/crt0.S#L77-L77). According to [this github thread](https://github.com/raspberrypi/pico-examples/issues/532), it can be overriden ([example](https://github.com/Blimp01/pico_non_blocking_timer/blob/master/non_blocking_timer.c#L16).

