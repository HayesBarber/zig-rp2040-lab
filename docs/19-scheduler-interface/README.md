# 19 - Scheduler Interface

Right now we have an `Algorithm` tagged union that acts as the abstraction over the scheduling algorithm, and currently has `round_robin` and `super_loop`. While this has worked thus far, I don't think this is the right abstraction going forward as we look to implement new algorithms. With the current approach, we are tied to these function signatures, and are lacking interal state. Future algorithms are going to use different data structures, and likely will have different/unique function signatures. Additionally, multi-core scheduling will likely need multiple instances of the scheduler (one per core).

I am proposing that we swap to a `Scheduler` interface, and have implementations of that interface per algorithm. The interface will define a constructor that accepts the tasks as an argument, so that implementations can then decide for themselves how to arrange the tasks.

For preemptive algorithms, there will also need to be methods for `tick`, `selectNext`, `blockCurrent`, and `makeReady`. The `selectNext` method should ideally replace the `schedulerSelectNext` that exists currently in the scheduler `mod.zig`, but that could be tricky since it is exported and we branch into it from PendSV's naked callconv. It may be the case that `schedulerSelectNext` simply invokes the schedulers function based on the core id. For cooperative algorithms, there can be a `run` method that is `noreturn`. 

Each scheduler implementation should also register it's own tasks, setup PSP, configure PendSV/Systick/watchdog, and define task exit. This may look the same for many implementations, so there can be a base implementation. The scheduler mod's `start` function should be a thin wrapper that zrt0 invokes. Really the entire mod should be pretty minimal, mainly holding the scheduler instances.

Note that the exising `Algorithm` tagged union will be deleted, as each `Scheduler` implementation will inherently be an algorithm.

## Zig Interfaces

In Zig there is no formal interface, but there are a few patterns to get that behavior. VTables, `@hasDecl`, `anytype`, and so on.

While I like the VTable approach, I am not sure that is great for the scheduler due to the fact that we probably won't be dynimcally creating these at runtime, and the cost of indirection. I don't think we necessarily _need_ to define an interface explicitly. As long as the cooperative/preemptive implementations have the expected methods, we should be able to swap them out with ease, and use comptime built-ins as needed.

## Post Implementation

Alrighty, I went with an approach that felt right for now. There is not an explicit "interface" as there is only one scheduler implementation active, and it is known at comptime. As compared to interface implementations that you create multiple of at runtime.

The main driver of this is this neat Zig syntax:

```zig
pub const SchedulerImpl = switch (root.SCHEDULER_ALGORITHM) {
    .round_robin => @import("round_robin/mod.zig"),
    .super_loop => @import("super_loop/mod.zig"),
};
```

Then `main.zig` defines the desired implementation:

```zig
pub const SCHEDULER_ALGORITHM = kernal.SchedulingAlgorithms.round_robin;
```

This allows for a comptime known type that I can easily swap out. Then, throughout the code base as needed, we check for `@hasDecl` before calling methods. For instance, running the scheudler only applies to preemptive algorithms:

```zig
pub export fn schedulerSelectNext(old_sp: usize) callconv(.c) usize {
    if (!@hasDecl(impl, "selectNext")) {
        unreachable;
    }

    return instance.selectNext(old_sp);
}
```

And in some cases we can throw a `@compileError` if an API is used that needs a preemptive scheudler:

```zig
if (!@hasDecl(scheduler.impl, "blockCurrent")) {
    @compileError("Chosen scheduler implementation has no ability to block a task");
}
```

So now each scheduler implementation can just needs to meet this comptime known contract.

I also moved the TCB inside the algorithm implementation, as I anticipate different algorithms needing different TCBs. `blockCurrent` and `makeReady` both take/return pointers to TCBs, so this was refactored for them to take/return `anyopaque` pointers. I don't think this will be a problem as all the caller really needs is a handle. If anything this is the exact use case for an opaque pointer.

