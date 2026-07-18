# 15 - Context Switching

The time has finally come to preempt a task and perform a context switch. This initial implementation will be a round robin schedule.

Looking back at chapter 5, we discussed how the processor will automatically push the minimum registers to save state on exception entry (`PSR`, `PC`, `LR`, `R12`, `R3`, `R2`, `R1`, and `R0`). That leaves `R4-R11` and the stack pointer for PendSV to save.

## MSP vs PSP

Something that needs to be flushed out is the use of the main stack pointer (MSP) and process stack pointer (PSP). My understanding is that tasks will use the PSP, and the scheduler will use MSP. I am not sure though how the PSP gets set up. In `exit_from_boot2.S`, the MSP gets set up. I think that the exception return value from PendSV is used to tell the processor what mode and stack pointer to use. Need to do some research here.

## Context Switch Sequence (Pre-implementation)

Here is my understanding of the context switch sequence:

- Exit from boot2 using MSP. Operating in priveledged thread mode
- zrt0 calls scheduler's `start()` function
  - set PendSV priority
  - for each TCB's stack, push an initial stack frame
    - `PSR = 0x01000000` (thumb bit set, nothing else active)
    - `PC = @intFromPtr(task.entry)`
    - `LR   = @intFromPtr(taskExit)`
    - `R0-R12 = 0` (order matters: `R12` -> `R3:0` -> `R11:4`)
    - `SP = R4` (bottom of initial frame)
      - Stack grows down
  - Set PSP to first task's SP
  - initialize SysTick
  - pend SV
  - `wfi` infinite loop
- SysTick ISR decrements current task's time slice, checks for expiry, and pends SV accordingly
- PendSV performs the context switch
  - Use `callconv(.naked)` to preserve register values on function entry
    - This effectively will require PendSV to be pure asm
    - If we want scheduler logic to be Zig, we can branch to it from asm
  - Save `R4-R11` and `PSP` to task's TCB
  - Run scheduler logic to choose next task
  - Restore new task's `R4-R11` and `PSP`
  - Set `LR` to `FFFFFFFD`, which is the `EXC_RETURN` value to return to thread mode and use PSP
  - `BX LR` for exception return

> There could be a step in the sequence to exit priveledged thread mode, for now I will omit this

## Post-implementation

Context switching is now working! I would like to discuss the details, and where the code base now sits.

- The sequence described above is accurate to the implementation, but there is some nuance around starting the first task
  - It is true that we need to push initial stack frames onto each task's stack
  - _However_, recall that PendSV will push `R4-R11` onto the interrupted task's stack
  - On the very first context switch, whichever task we choose to be swapped first would now have an extra set of `R4-R11` values pushed onto it's stack if we had pushed a full frame
  - So in our implementation, we push only the hardware stack frame (volitile registers) for task index 0, and let PendSV push the rest on the first swap
  - Note that on the first swap task 0 never actually ran, so task 1 is the actual first task to run. This was not a strict requirement for me, but could be addressed but changing the initial task index to be `len(tasks) - 1`
- Since we come out of boot using the MSP, the PSP still needs to be initialized to task 0's stack pointer. This is done during the scheduler's `start()` function
- We don't manipulate the `CONTROL` register to set `SPSEL` to PSP, instead we explicitly exit PendSV with `EXC_RETURN` as `0xFFFFFFFD` which informs that processor to use PSP
- Depending on the scheduler algorithm, a task may or may not be expected to exit
  - In a super loop for instance, the tasks should cooperate and perform "one iteration" of their task
  - But in preemptive context switching the scheuler will force the swap, so tasks _shouldn't_ return
  - When using an algorithm that expects `noreturn` but still a task managed to exit, there is a `taskExit()` function that simply pends SV and then `wfi`
    - May refine this to instead restart the task?
- Recall that the stack grows downward towards lower memory addresses. This made for (IMO) some tricky details to visualize in the implementation
  - When pushing the initial stack frames, you may think that you would reverse the values to satisfy this, but you do not. The values are going to have increasing memory addresses, so the first value pushed is the lowest address, and thus the top of the stack
  - So the gist for doing this in Zig would be to subtract from your SP to make room, and then push the values starting with what should be the top of the stack
  - The same logic applies for PendSV in asm. Subtract to push, and add to pop
- PendSV uses `stmia` and `ldmia` for pushing and popping from PSP during the context switch
  - RP2040 doesn't use full Thumb-2, which made this more verbose than I think was necessary

Some other genreal notes on the code base:

- The was some orginization for the kernel subdirectory structure
  - Goal was to make files smaller and logically group things together
  - I recently discovered that I misspelled kernel in the code-base. IDK if I will fix that lol. Gives it some character
- I have structured things to make scheduling algorithms swappable, for later comparisons
- There is now a hard-fault ISR that rapidly blinks the LED
  - This was heavily used during this implementation due to pushing stack frames that led to hard faults

## References

- Chapter 05 - Exception Entry and Register Stacking
- https://stackoverflow.com/questions/67001374/cortex-m0-msp-psp-context-switching
- https://developer.arm.com/documentation/107706/0100/Exceptions-and-interrupts-overview/EXC-RETURN
- https://developer.arm.com/documentation/dui0662/b/The-Cortex-M0--Processor/Programmers-model/Core-registers

