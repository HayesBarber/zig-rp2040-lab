# 15 - Context Switching

The time has finally come to preempt a task and perform a context switch. This initial implementation will be a round robin schedule.

Looking back at chapter 5, we discussed how the processor will automatically push the minimum registers to save state on exception entry (`PSR`, `PC`, `LR`, `R12`, `R3`, `R2`, `R1`, and `R0`). That leaves `R4-R11` and the stack pointer for PendSV to save.

## MSP vs PSP

Something that needs to be flushed out is the use of the main stack pointer (MSP) and process stack pointer (PSP). My understanding is that tasks will use the PSP, and the scheduler will use MSP. I am not sure though how the PSP gets set up. In `exit_from_boot2.S`, the MSP gets set up. I think that the exception return value from PendSV is used to tell the processor what mode and stack pointer to use. Need to do some research here.

## Context Switch Sequence

Here is my understanding of the context switch sequence:

- Task registration
  - initializes task control blocks
  - for each TCB's stack, push an initial stack frame
    - `PSR = 0x01000000` (thumb bit set, nothing else active)
    - `PC = @intFromPtr(task.entry)`
    - `LR   = @intFromPtr(taskExit)`
    - `R0-R12 = 0` (order matters: `R12` -> `R3:0` -> `R11:4`)
    - `SP = top of stack` (remember that stack grows down, so we will be inserting at the end of the buffer)
- Exit from boot2 using MSP. Operating in priveledged thread mode
- zrt0 calls scheduler's `start()` function
  - set PendSV priority
  - set PSP to be the first task's SP
  - Set `CONTROL` register bit 1 (`SPSEL`) to make PSP the current stack pointer
    - Use `ISB` instruction to flush pipeline
  - initialize SysTick
  - pend SV
  - `wfi` infinite loop
- SysTick ISR checks for time slice expiry, and pends SV accordingly
- PendSV performs the context swith
  - Use `callconv(.naked)` to preserve register values on function entry
  - Save `R4-R11` and `PSP` to task's TCB
  - Run scheduler logic
  - Restore new task's `R4-R11` and `PSP`
  - `EXC_RETURN` should be `FFFFFFFD` to return to thread mode and use PSP
    - this is implicit, not actually returned from PendSV

## References

- Chapter 05 - Exception Entry and Register Stacking
- https://stackoverflow.com/questions/67001374/cortex-m0-msp-psp-context-switching
- https://developer.arm.com/documentation/107706/0100/Exceptions-and-interrupts-overview/EXC-RETURN
- https://developer.arm.com/documentation/dui0662/b/The-Cortex-M0--Processor/Programmers-model/Core-registers

