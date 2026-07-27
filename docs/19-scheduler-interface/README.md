# 19 - Scheduler Interface

Right now we have an `Algorithm` tagged union that acts as the abstraction over the scheduling algorithm, and currently has `round_robin` and `super_loop`. While this has worked thus far, I don't think this is the right abstraction going forward as we look to implement new algorithms. With the current approach, we are tied to these function signatures, and are lacking interal state. Future algorithms are going to use different data structures, and likely will have different/unique function signatures. Additionally, multi-core scheduling will likely need multiple instances of the scheduler (one per core).

I am proposing that we swap to a `Scheduler` interface, and have implementations of that interface per algorithm. The interface will define a constructor that accepts the tasks as an argument, so that implementations can then decide for themselves how to arrange the tasks.

For preemptive algorithms, there will also need to be methods for `tick`, `selectNext`, `blockCurrent`, and `makeReady`. The `selectNext` method should ideally replace the `schedulerSelectNext` that exists currently in the scheduler `mod.zig`, but that could be tricky since it is exported and we branch into it from PendSV's naked callconv. It may be the case that `schedulerSelectNext` simply invokes the schedulers function based on the core id. For cooperative algorithms, there can be a `run` method that is `noreturn`. 

Each scheduler implementation should also register it's own tasks, setup PSP, configure PendSV/Systick/watchdog, and define task exit. This may look the same for many implementations, so there can be a base implementation. The scheduler mod's `start` function should be a thin wrapper that zrt0 invokes. Really the entire mod should be pretty minimal, mainly holding the scheduler instances.

Note that the exising `Algorithm` tagged union will be deleted, as each `Scheduler` implementation will inherently be an algorithm.

## Zig Interfaces

In Zig there is no formal interface, but there are a few patterns to get that behavior. VTables, `@hasDecl`, `anytype`, and so on.

While I like the VTable approach, I am not sure that is great for the scheduler due to the fact that we probably won't be dynimcally creating these at runtime, and the cost of indirection. I don't think we necessarily _need_ to define an interface explicitly. As long as the cooperative/preemptive implementations have the expected methods, we should be able to swap them out with ease, and use comptime built-ins as needed.

