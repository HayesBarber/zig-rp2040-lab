# 07 - Multi Core

It could be pre-mature to do this chapter now, but I do plan to have this project's scheduler run tasks across both cores of the RP2040. The plan for this chapter it to learn how to utilize both cores, the nuances of doing so, and write a simple dual-core program.

As mentioned in the `01-boot`, core 1 goes to sleep at boot until woken by user code. There is a section in the RP2040 datasheet `2.8.2. Launching Code On Processor Core 1` (page 131) that describes the process of launching code on core 1. The cores will communicate via inter-processor FIFOs (essentially a message queue). This will be "lockstep" communication, which I guess just means that it is blocking synchronous.

There is some C code in the datasheet to demonstrate the procedure, which essentially just sends a command sequence over FIFO. It can also be seen in [the pico sdk](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/pico_multicore/multicore.c#L176).

```c
const uint32_t cmd_sequence[] = {0, 0, 1, (uintptr_t) vector_table, (uintptr_t) sp, (uintptr_t) entry};
```

Sending this to core 1 provides it with it's initial stack pointer, entry point, and vector table. Not sure what the leading 0,0,1 does, potentially a magic sequence to ensure cores are syncronized.

The FIFO message queues reside in the Single-cycle IO block (SIO), which is memory mapped within the `IOPORT` space (0xd0000000-0xdfffffff).

Section `2.3.1. SIO` (page 27) of the datasheet has a good diagram on the archetecture, and section `2.3.1.4. Inter-processor FIFOs (Mailboxes)` (page 31) gives more details around using the message queues.

Cores write outgoing data by writing to `FIFO_WR`, and read incoming data by reading `FIFO_RD`. There is also a `FIFO_ST` register for status signals.

SIO registers can be found in section `2.3.1.7. List of Registers` (page 42) of the datasheet.

- `SIO` Base: 0xd0000000
- `FIFO_ST`: Offset 0x050
- `FIFO_WR`: Offset 0x054
- `FIFO_RD`: Offset 0x058

The pico sdk is essentially writing/reading to these memory locations, and using [sev](https://developer.arm.com/documentation/dui0489/i/arm-and-thumb-instructions/sev) and [wfe](https://developer.arm.com/documentation/ddi0406/cb/Application-Level-Architecture/Instruction-Details/Alphabetical-list-of-instructions/WFE) to signal/block.

Note that the sdk also [disables the FIFO IRQ](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/pico_multicore/multicore.c#L182) before the handshake, and then re-enables it (if it was enabled). If the core had ths IRQ enabled, it would fire and the function performing the handshake would never get to see the response.

`SIO_IRQ_PROC0` and `SIO_IRQ_PROC1` are the interrupts for FIFO (15 and 16 respectively), and can be seen in section `2.3.2. Interrupts` (page 60) or in the sdk's [irq.h](https://github.com/raspberrypi/pico-sdk/blob/master/src/host/hardware_irq/include/hardware/irq.h#L81-L82).

Note that the function one would likely call when using the sdk is [multicore_launch_core1](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/pico_multicore/multicore.c#L164), which first pushes some items onto core 1's stack so that it can install a stack guard and do other initialization before calling the provided entry function.

## Excersise 10: Multi-core Blinky

The goal will be to write a program in which one core blinks the LED, and the other prints.

---

I opted to use the pico sdk function instead of re-implementing it in pure zig, so the program is quite simple. Still had some learnings:

- I needed to include `pico_multicore` in the `CMakeLists.txt` to include the multicore functionality
- Since the `multicore_launch_core1` function is defined as extern and takes a function pointer, Zig requires a calling convention (e.g. `callconv(.c)`)
