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
  - Check kernel ring buffer for data
    - If data -> consume it and don't block
  - Set this task as waiting on UART so that the ISR has a reference
  - Invoke the scheduler to mark this task as blocked
  - Once this task is re-scheduled, copy data from UART ISR ring buffer to task buffer and return to task
  - It will be up to the task to discern if that is all the data it needs or to wait for more
- Internal to the ISR:
  - Check the interrupt source for RX/RX Timeout using the `UARTMIS` register
    - Reading a 1 on a given bit means it's pending
  - Have a ring buffer to place data from the UART FIFO
  - Drain the UART FIFO into the ring buffer
  - If there is a task currently blocked, mark it as ready
    - Mark task ready on both RX and RX timeout
    - Do not PendSV, let Systick handle

For now we aren't implementing a new scheduler alogrithm, but the round robin should check that the next task is not blocked. We may also want to condisider a data oriented design instead of one big task buffer?

## Post Implementation

- External interrupts added to the vector table struct in zrt0, with uart0 being specified in the actual instance
- Ring Buffer data structure added. Drops new bytes when at capacity
- Helper functions added for [CPS instructions](https://developer.arm.com/documentation/dui0646/c/The-Cortex-M7-Instruction-Set/Miscellaneous-instructions/CPS) to enable/disable interrupts for critical sections
- The UART setup in the core module configures the interrupt as described above
- The UART ISR checks the RX/RX Timeout, writes to the ring buffer, clears the interrupt, and marks waiting task as ready
- The UART read API:
  - Enters a critical section by disabling interrupts
  - Checks if existing data is in the ring buffer, if so re-enable interrupts and return available
  - Blocks the current task, and re-enables interrupts
    - This will PendSV and schedule the next task
  - Upon re-schedule, return the read from the ring buffer
- The round robin scheduler now checks canidates for not being blocked
  - If all tasks blocked, return the current task
- The scheduler exposes APIs to block the current task, and make a task ready
  - Blocking the current task will pend SV and return a pointer to the blocked task
    - This needs to be in a critical section from the caller

