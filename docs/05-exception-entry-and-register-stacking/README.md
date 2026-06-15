# 05 - Exception Entry and Register Stacking

For premptive scheduling, there is a need to save the state of the task being preempted, and then load the state of the task that being swapped to (aka a context switch).

My current understanding is that you would push all the registers onto the stack, but this section aims to get a deeper understanding of this process.

## Registers

In the RP2040 datasheet, there is a section `2.4.3.5. Processor core registers summary` (page 72) which provides a table of the processors core register set. Note that this is an ARM thing rather than specific to the RP2040.

Unlike some of the previous registers we have worked with, these are not memory mapped. You interact with them via CPU instructions directly.

- `R0-R12`: General purpose registers
- `R13`: Stack pointer
  - Depending on the `CONTROL` register (see below), this could be the MSP (main stack pointer) or PSP (Process Stack Pointer)
  - I think MSP / PSP is a kernal mode / user mode thing, so I am not sure if we will use this yet
    - Presummably each task may have it's own stack
- `R14`: Link Register (LR)
  - Stores return address for function calls and whatnot
  - E.g. to return from a function in assembly, one might `bx lr`
- `R15`: Program Counter (PC)
  - Memory address of the next instruction
- `PSR`: Program Status Register
  -  Combines the following:
    - `APSR`: Application Program Status Register
      - ALU flags
    - `IPSR`: Interrupt Program Status Register
      - Info about currently executing exception or interrupt
    - `EPSR`: Execution Program Status Register
      - Tracks Thumb, If-Then, and Interruptible-Continuable Instruction states
- `PRIMASK`: prevents activation of all exceptions with configurable priority
- `CONTROL`: Controls the stack used (MSP/PSP)
  - In an OS, the kernal would use MSP and threads the PSP

