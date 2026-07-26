# 19 - Scheduler Interface

Right now we have an `Algorithm` tagged union that acts as the abstraction over the scheduling algorithm, and currently has `round_robin` and `super_loop`. While this has worked thus far, I don't think this is the right abstraction going forward as we look to implement new algorithms. With the current approach, we are tied to these function signatures, and are lacking interal state. Future algorithms are going to use different data structures, and likely will have different/unique function signatures. Additionally, multi-core scheduling will likely need multiple instances of the scheduler (one per core).

I am proposing that we swap to a `Scheduler` interface, and have implementations of that interface per algorithm. The interface will define a constructor that accepts the tasks as an argument, so that implementations can then decide for themselves how to arrange the tasks.

For preemptive algorithms, there will also need to be methods for `tick`, `selectNext`, `blockCurrent`, and `makeReady`. The `selectNext` method should ideally replace the `schedulerSelectNext` that exists currently in the scheduler `mod.zig`, but that could be tricky since it is exported and we branch into it from PendSV's naked callconv. It may be the case that `schedulerSelectNext` simply invokes the schedulers function based on the core id.

For cooperative algorithms, there can be a `run` method that is `noreturn`. How should we distinguish between cooperative and preemptive? A few ideas:

1. Have some boolean method `isCooperative`
2. Use the `@hasDecl` built-in
3. Use a tagged union

Each scheduler implementation should also register it's own tasks, setup PSP, configure PendSV/Systick/watchdog, and define task exit. This may look the same for many implementations, so there can be a base implementation. The scheduler mod's `start` function should be a thin wrapper that zrt0 invokes. Really the entire mod should be pretty minimal, mainly holding the scheduler instances.

Note that the exising `Algorithm` tagged union will be deleted, as each `Scheduler` implementation will inherently be an algorithm.

