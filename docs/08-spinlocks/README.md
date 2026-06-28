# 08 - Spinlocks

While I am still not 100% sure how things will end up, I would imagine I will need some form of synchronization between cores. The RP2040 has 32 hardware spinlocks that can be used for mutual exclusion.

The datasheet has a `2.3.1.3. Hardware Spinlocks` section (page 30) documents that the spinlocks are memory mapped in the SIO registers. Registers are `SPINLOCK0`..`SPINLOCK31` with offsets `0x100, 0x104, …, 0x178, 0x17c`. Recall from the last chapter that the SIO Base is 0xd0000000.

To claim a lock you read from the register. Reading a non-zero value means the lock was claimed. Both cores attempting to claim on the same cycle will result in core 0 winning. Writing any value will release the lock. The `SPINLOCK_ST` register can be used to observe the state of all locks.

As the name implies, software may "spin" on the lock while trying to claim it. This is not efficient to do for a long time. Higher level synchronization mechanisms like mutexs and semaphores may use spinlocks to protect short critical sections.

The pico sdk offers [mutexs](https://github.com/raspberrypi/pico-sdk/blob/master/src/common/pico_sync/include/pico/mutex.h) and [semaphores](https://github.com/raspberrypi/pico-sdk/blob/master/src/common/pico_sync/include/pico/sem.h). Notice that the [spin_lock_blocking](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/hardware_sync_spin_lock/include/hardware/sync/spin_lock.h#L301) function will disable interrupts before aquiring the lock. One could imagine a scenario where application code has obtained a lock, gets interrupted, and the ISR wants to obtain the same lock...

## Fork in the road

Considering that the synchronization mechanisms provided by the pico sdk have their own structs and whatnot, defining that all as extern in Zig may be a hassle. I think there are a few options:

1. Pure Zig spinlocks
  - Use memory mapped locations as done if previous exercises
  - Simple
  - Ineffecient to use for the actual scheduler? Should be a short critical section I would guess
2. Define sdk functions as extern and manually define C compatible structs
  - Kinda tedious
3. Get FFI working for the SDK
  - Add the necessary headers to the `build.zig` and be able to use the translation
  - Could limit to only the synchronization includes

I am leaning towards option 3. I didn't do this before as it seems tricky, but it may be worth figuring out.

In the Zig docs for 0.16, it states the [cImport is deprecated](https://ziglang.org/download/0.16.0/release-notes.html#cImport-Moving-to-Build-System) in favor of moving it to the build system.

### Update on option 3

I was able to seemingly get the include paths through trial and error:

```c
// c.h
#include pico/sync.h
```

```zig
// build.zig
const translate_c = b.addTranslateC(.{
    .root_source_file = b.path("c.h"),
    .target = target,
    .optimize = optimize,
});
translate_c.addIncludePath(b.path("pico-sdk/src/boards/include/boards"));
translate_c.addIncludePath(b.path("pico-sdk/src/common/pico_time/include"));
translate_c.addIncludePath(b.path("pico-sdk/src/host/hardware_timer/include"));
translate_c.addIncludePath(b.path("pico-sdk/src/host/hardware_sync/include"));
translate_c.addIncludePath(b.path("pico-sdk/src/common/pico_sync/include"));
```

However, it is still failing to compile with a bunch of compilation errors like `critical_section.h:92:80: error: expected ';', found ')'`. I am not sure what the issue is. For the sake of this chapter I may go with option 1 and use raw spinlocks.

## Exercise 11: Intentional Race Condition

We will write a program that intentially has a race condition, and then fix it in the next excercise using spinlocks.

---

In `main.zig`, both cores are reading a global shared variable and incrementing it 1 million times. One would expect the variable to be equal to 2 million at the end. The actual output is:

```txt
beginning core 0 iterations
beginning core 1 iterations
core 0 iterations done
core 1 iterations done
Expected: 2000000
Actual:   1054228
```

Since the shared variable is not protected by mutual exclusion, both cores may read in the same value on a given iteration. For example:

- Core 0 reads 10, and writes 11
- Core 1 also reads 10, and also writes 11

This causes some iterations to get "lost" so to speak, which is why the actual value is smaller than expected.

One interesting thing that occured is in the main function when core 0 is waiting for core 1 to complete (by incrementing `DONE`). If we don't force the retrieval of `DONE` by making a volatile cast, the loop never terminates. I beleive this is because the compiler is free to cache `DONE` (e.g. as a stack var) since the loop doesn't modify it. So despite core 1 incrementing it and `DONE` having the value 2 in RAM, core 0 never sees it because it's not going to RAM, instead using it's cached value. Lets try and look at the assembly to confirm this suspicion.

First, we will adjust the while loop in `main.zig` to not be volatile:

```zig
while (DONE < 2) {}
```

Then object dump:

```bash
arm-none-eabi-objdump -D -m arm -M force-thumb race-condition.elf > asm.s
nvim asm.s
```

Here is the assembly regarding the loop:

```asm
10006faa:	4f12      	ldr	r7, [pc, #72]	@ (10006ff4 <main+0x94>)
10006fac:	7838      	ldrb	r0, [r7, #0]
10006fae:	1c41      	adds	r1, r0, #1
10006fb0:	7039      	strb	r1, [r7, #0]
10006fb2:	2800      	cmp	r0, #0
10006fb4:	d00c      	beq.n	10006fd0 <main+0x70>
```

Lets break it down:

1. Load pointer to `DATA` into `r7` (e.g. `r7 = &DONE`)
2. Load a byte from that address into `r0` (`DONE` is a u8)
3. Increment `r0` by 1 and store that in `r1`
4. Store the low 8 bits of `r1` into the memory location of `r7` (aka memory location of `DONE`)
5. Compare `r0` to 0
  - Note that `r0` is the value ___before___ incrementing
  - This is not necessarily a problem under normal circumstances. Since `DONE` is a u8, if the old value was zero then old += 1 is 1 and 1 < 2 so loop forever. If the old value was >= 1 then the new value is >= 2 so skip the loop
6. Brach to `10006fd0` if the old value of `DONE` was 0

If we look at `10006fd0` we see an infinite loop:

```asm
10006fd0:	e7fe      	b.n	10006fd0 <main+0x70>
```

This confirms our suspicion that compiler omptimizations have caused the program to only evaluate the value of `DONE` once, and thus the infinite loop. Lets put the volatile code back and look at the assembly again:

```asm
10006faa:	4f12      	ldr	r7, [pc, #72]	@ (10006ff4 <main+0x94>)
10006fac:	7838      	ldrb	r0, [r7, #0]
10006fae:	1c40      	adds	r0, r0, #1
10006fb0:	7038      	strb	r0, [r7, #0]
10006fb2:	7838      	ldrb	r0, [r7, #0]
10006fb4:	2802      	cmp	r0, #2
10006fb6:	d3fc      	bcc.n	10006fb2 <main+0x52>
```

Now we can see that the value of `DONE` is continuously loaded into `r0` and compared against 2.

