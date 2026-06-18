# 06 - PendSV Interrupt

From my research so far it seems that the SysTick ISR, while responsible for running the scheduler, will not actually perform the context switch. RTOS's standardly use PendSV (Pending Supervisor Call) instead.

PendSV is a software trigger exception. It can be triggered by the memory mapped `ICSR` register. Specifically by setting the `PENDSVSET` bit to 1 (bit 28).

Per the [ARM docs](https://developer.arm.com/documentation/107706/0100/System-exceptions/Pended-SVC---PendSV), PendSV is typically configured to have the lowest interrupt priority. Considering the a context switch is pure overhead, using the lowest priority allows other time sensitive operations to complete.

The [exception number](https://developer.arm.com/documentation/dui0497/a/the-cortex-m0-processor/exception-model/exception-types) of PendSV is 14, and setting the priority can be done via the memory mapped Interrupt Priority Registers (`NVIC_IPR[0:7]`). Specifically the `NVIC_IPR3` register which can assign priority to interrupt 14.

## Exercise 9: Configure PendSV priority and trigger from SysTick

