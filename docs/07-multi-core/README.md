# 07 - Multi Core

It could be pre-mature to do this chapter now, but I do plan to have this project's scheduler run tasks across both cores of the RP2040. The plan for this chapter it to learn how to utilize both cores, the nuances of doing so, and write a simple dual-core program.

As mentioned in the `01-boot`, core 1 goes to sleep at boot until woken by user code. There is a section in the RP2040 datasheet `2.8.2. Launching Code On Processor Core 1` (page 131) that describes the process of launching code on core 1. The cores will communicate via inter-processor FIFOs (essentially a message queue). This will be "lockstep" communication, which I guess just means that it is blocking synchronous.

There is some C code in the datasheet to demonstrate the procedure, which essentially just sends a command sequence over FIFO. It can also be seen in [the pico sdk](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/pico_multicore/multicore.c#L176).

```c
const uint32_t cmd_sequence[] = {0, 0, 1, (uintptr_t) vector_table, (uintptr_t) sp, (uintptr_t) entry};
```

Sending this to core 1 provides it with it's initial stack pointer, entry point, and vector table.

The FIFO message queues reside in the Single-cycle IO block (SIO), which memory mapped within the `IOPORT` space (0xd0000000-0xdfffffff).

Section `2.3.1. SIO` (page 27) of the datasheet has a good diagram on the archetecture, and section `2.3.1.4. Inter-processor FIFOs (Mailboxes)` (page 31) gives more details around using the message queues.

Cores write outgoing data by writing to `FIFO_WR`, and read incoming data by reading `FIFO_RD`. There is also a `FIFO_ST` register for status signals.

- `SIO` Base: 0xd0000000
- `FIFO_ST`: Offset 0x050
- `FIFO_WR`: Offset 0x054
- `FIFO_RD`: Offset 0x058

