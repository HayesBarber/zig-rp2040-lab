# 15 - Context Switching

The time has finally come to preempt a task and perform a context switch. This initial implementation will be a round robin schedule.

Looking back at chapter 5, we discussed how the processor will automatically push the minimum registers to save state on exception entry (`PSR`, `PC`, `LR`, `R12`, `R3`, `R2`, `R1`, and `R0`). That leaves `R4-R11` and the stack pointer for PendSV to save.

## MSP vs PSP

Something that needs to be flushed out is the use of the main stack pointer (MSP) and process stack pointer (PSP). My understanding is that tasks will use the PSP, and the scheduler will use MSP. I am not sure though how the PSP gets set up. In `exit_from_boot2.S`, the MSP gets set up. I think that the exception return value from PendSV is used to tell the processor what mode and stack pointer to use. Need to do some research here.

Here is my understanding of the context switch sequence (from boot exit):

- Exit from boot2 using MSP and in priveledged thread mode

## References

- https://stackoverflow.com/questions/67001374/cortex-m0-msp-psp-context-switching
- https://developer.arm.com/documentation/107706/0100/Exceptions-and-interrupts-overview/EXC-RETURN

