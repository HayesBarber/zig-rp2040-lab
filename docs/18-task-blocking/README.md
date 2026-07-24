# 18 - Task Blocking

In order to do more advanced scheduling past a round robin, we need to have a mechanism for moving tasks into `State.Blocked`. In the current state tasks could be burning cycles polling IO, and would be better off not being scheduled until an interrupt fires for the respective IO peripheral.

I am thinking that the kernel will expose APIs for IO that internally move tasks to blocked and invoke the scheduler. That task will remain blocked until the respective IO ISR moves the task back to ready.

To start we will have the kernal expose a UART receive API that blocks the task. The RP2040 has an interrupt for UART RX called `UARTRXINTR` (section `4.2.6.2` of the datasheet) that we will need to wire up. We can configure a trigger point based on how much data is in the FIFO using the `UARTIFLS` register. If the data being recieved does not divide evenly into the threshold, then we can rely on the recieve timeout interrupt `UARTRTINTR`. The interrupt can be cleared manually or by reading the data from the FIFO.

A task blocked on UART may not be immediately scheduled upon recieving data, and the FIFO only holds like 32 bytes. We may want the ISR to clear the FIFO and write it to a ring buffer that is larger. We could also setup direct memory access (DMA), but I don't think I want to use this for RX.

The ISR will also need to know which tasks are blocked on UART. It may only make sense that 1 task listen to UART unless we want to copy data into multiple places. Either way there can be either a task pointer or queue for the ISR to read/update.

## `UARTRXINTR` / `UARTRTINTR` Interrupt Setup and Location in Vector Table

## Control Flow

## Post Implementation

