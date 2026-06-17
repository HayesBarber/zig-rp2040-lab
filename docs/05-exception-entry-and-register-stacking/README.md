# 05 - Exception Entry and Register Stacking

For premptive scheduling, there is a need to save the state of the task being preempted, and then load the state of the task that being swapped to (aka a context switch).

My current understanding is that you would push all the registers onto the stack, but this section aims to get a deeper understanding of this process.

## ARM Cortex-M0+ Registers

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

On exception entry, the processor needs to know how to return to where it was before it was interrupted. To do this, it saves the ___minimal viable state___, which are registers `PSR`, `PC`, `LR`, `R12`, `R3`, `R2`, `R1`, and `R0`. This makes up an Exception Stack Frame, and the registers are pushed in that order (`R0` is top of the stack).

This is important for our scheduler because it will be up to us to save other registers (like `R4-R11` and `SP`).

## Exercise 8: Print registers in ISR

To better understand the above, we will build off our SysTick ISR and have the function print some registers for us to try and make sense of.

---

There are some interesting things happening in `main.zig`, lets break down the code and the output.

Notice that `isr_systick` is now `callconv(.naked)`. This will tell zig to not have any function prologue or epilogue, which in this case is useful so that the registers are not manipulated before we can get them into a known location to inspect.

The SysTick ISR is now raw assembly:

```asm
mrs r0, msp
mov r1, lr
ldr r2, =isr_systick_impl
bx r2
```

1. `mrs r0, msp`: Move main stack pointer into `r0`
> `mrs` moves from a special register to a general register
2. `mov r1, lr`: Move the link register into `r1`
3. `ldr r2, =isr_systick_impl`: Load the address of `isr_systick_impl` into `r2`
4. `bx r2`: Branch to `r2` (aka `isr_systick_impl`)

`r0` and `r1` will be the 2 args passed into `isr_systick_impl`, and represent the exception frame and exe_return values. The ISR implementation simply prints these values every second.

Lets now examine the output:

```txt
r0=2000319c r1=00000000 r2=40054000 r3=d0000128 r12=00000000 lr=10001133 pc=10001174 xpsr=21000000 EXC_RETURN=fffffff9
```

The program counter (`pc=10001174`) is the instruction to return to after the ISR. We can confirm this address makes sense for our program by doing an objdump and searching for that address:

```bash
arm-none-eabi-objdump -D -m arm -M force-thumb stacking.elf > asm.s
nvim asm.s
```

When searching for `10001174`, I see this line:

```asm
10001174:	e7e5      	b.n	10001142 <sleep_ms+0xae>
```

Which aligns with our blinky program that uses `sleep_ms`.

The `EXC_RETURN=fffffff9` value is ARM saying to return from the exception in thread mode and to use the MSP. This value is kept in the link register for the exception and the hardware knows how to handle it when it is popped into the program counter on exception exit.

## References

- https://dev.to/amanprasad/decoding-exception-entry-exit-on-arm-cortex-mx-5fmc

