# 19 - Scheduler Interface

Right now we have an `Algorithm` tagged union that acts as the abstraction over the scheduling algorithm, and currently has `round_robin` and `super_loop`. While this has worked thus far, I don't think this is the right abstraction going forward as we look to implement new algorithms. With the current approach, we are tied to these function signatures, and are lacking interal state. Future algorithms are going to use different data structures, and likely will have different/unique function signatures. Additionally, multi-core scheduling will likely need multiple instances of the scheduler (one per core).

I am proposing that we swap to a `Scheduler` interface, and have implementations of that interface per algorithm. The interface will define a constructor that accepts the tasks as an argument, so that implementations can then decide for themselves how to arrange the tasks. For preemptive algorithms, there will also need to be methods for `tick`, `selectNext`, `blockCurrent`, and `makeReady`. Cooperative algorithms can expose a `run` method.

Note that the exising `Algorithm` tagged union will be deleted, as each `Scheduler` implementation will inherently be an algorithm.

