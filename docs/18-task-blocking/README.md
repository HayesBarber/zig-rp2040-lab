# 18 - Task Blocking

In order to do more advanced scheduling past a round robin, we need to have a mechanism for moving tasks into `State.Blocked`. In the current state tasks could be burning cycles polling IO, and would be better off not being scheduled until an interrupt fires for the respective IO peripheral.

I am thinking that the kernel will expose APIs for IO that internally move tasks to blocked and invoke the scheduler. That task will remain blocked until the respective IO ISR moves the task back to ready.

To start we will have the kernal expose a UART receive API that blocks the task. The RP2040 has an interrupt for UART RX called `UARTRXINTR` (section `4.2.6.2` of the datasheet) that we will need to wire up. We can configure a trigger point based on how much data is in the FIFO using the `UARTIFLS` register. If the data being recieved does not divide evenly into the threshold, then we can rely on the recieve timeout interrupt `UARTRTINTR`. The interrupt can be cleared manually or by reading the data from the FIFO.

A task blocked on UART may not be immediately scheduled upon recieving data, and the FIFO only holds like 32 bytes. We may want the ISR to clear the FIFO and write it to a ring buffer that is larger. We could also setup direct memory access (DMA), but I don't think I want to use this for RX.

The ISR will also need to know which tasks are blocked on UART, so that it can unbock them. It may only make sense that 1 task listen to UART unless we want to copy data into multiple places. Either way there can be either a task pointer or queue for the ISR to read/update.

## `UARTRXINTR` / `UARTRTINTR` Interrupt Setup and Location in Vector Table

The is a single interrupt for UART, and the ISR will determine the cause of the interrupt (RX, TX, etc). Section `2.3.2` of the datasheet shows the IRQ numbers, with UART0 being 20 and UART1 being 21 (we are only currently using UART0). As such, we will need to put the UART ISR in that location in the zrt0 vector table.

Once the UART ISR is in the vector table, we also need to enable the interrupt using the `NVIC_ISER` register (offset `0xe100` from Cortex base). In this case we will set bit 20.

Next we will configure the trigger level by using the `UARTIFLS` register bits 5:3 (offset `0x034` from UART base). Setting these bits to b0000 will set the trigger point to 1/8 full (4 bytes).

Next we will enable `UARTRXINTR` and `UARTRTINTR` interrupt sources by using the `UARTIMSC` register (offset `0x038` from UART base). We will set bits 4 and 6.

Lastly, for good measure, we will clear any pending UART interrupts at startup. We will use the `UARTICR` register (offset `0x044` from UART base) and set bits 4 and 6 (or just write max value to clear all).

## Control Flow

The control flow for the blocking UART read will be as follows:

- Kernel exposes a UART read API
- A task invokes the read, and provides a buffer to place data
- Internal to the API:
  - Register this task as the current reader so that the ISR has a reference
  - Invoke the scheduler to mark this task as blocked and schedule next
  - Once this task is re-scheduled, copy data from UART ISR ring buffer to task buffer and return to task
  - It will be up to the task to discern if that is all the data it needs or to wait for more
- Internal to the ISR:
  - Have a ring buffer to place data from the UART FIFO
  - Drain the UART FIFO into the ring buffer
  - If there is a task currently blocked, mark it as ready
    - Need to determine if we should unblock only on timeout? Or when ring buffer is approaching full? Or on every RX?
  - Potentially pend SV

## Post Implementation

