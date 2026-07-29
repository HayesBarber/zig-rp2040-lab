# 20 - Symmetric Multiprocessing

Symmetric multiprocessing, in the context of this lab, is the idea that both cores are running their own instance of the same scheduling algorithm. They still very well can/will pull from the same task queue. We need to spin up the second core, as well as ensure there is a mutual exclusion mechanism for accessing global memory. We have covered both multi-core and spinlocks in previous chapters, but it is now time to fit it into our scheduler/kernel implementation. We also used the pico-sdk to launch a task on core 1, and will need to implement this outselves.

## Spinlock

Since the scheduler itself will be trying to obtain the lock, it won't be able to block the task and pend SV. Compare that to a mutex implementation that might put the task on a waiting queue. We very well may want that mutex implementation for later though.

The goal will be to add a spinlock implementation for the kernel module. It should be multi-core safe, and handle interrupt enabling/disabling for the critical section of obtaining the lock.

