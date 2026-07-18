# 16 - Timer Peripheral

In chapter 04 we covered timer interrupts, and landed on using SysTick to drive the context switch. We did mention that other timer peripherals exist, and this chapter will focus on the RP2040's timer peripheral as described in section `4.6`.

While SysTick will continue to drive the context switch, I would like to see if the timer peripheral is viable to use for measuring latency. Even if it ends up not being precise enough, I don't think this will be a waste of time to learn!

