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



