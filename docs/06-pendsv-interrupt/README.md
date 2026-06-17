# 06 - PendSV Interrupt

From my research so far it seems that the SysTick ISR, while responsible for running the scheduler, will not actually perform the context switch. RTOS's standardly use PendSV (Pending Supervisor Call) instead.

Per the [ARM docs](https://developer.arm.com/documentation/107706/0100/System-exceptions/Pended-SVC---PendSV), PendSV is typically configured to have the lowest interrupt priority. Considering the a context switch is pure overhead, using the lowest priority allows other time sensitive operations to complete.

The interrupt/exception number of PendSV is 14, and setting the priority can be done via the memory mapped Interrupt Priority Registers (`NVIC_IPR[0:7]`)

