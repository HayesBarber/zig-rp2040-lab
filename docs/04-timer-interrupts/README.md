# 04 - Timer Interrupts

Naturally a scheduler is going to need to define an interrupt handler so that it can preempt tasks and perform context switches.

## Exercise 7: Blinky interrupt

The goal will be to blink the onboard LED on a timer interrupt loop. Something like:

1. Register timer interrupt
2. Interrupt fires -> blink
3. Re-register timer interrupt

