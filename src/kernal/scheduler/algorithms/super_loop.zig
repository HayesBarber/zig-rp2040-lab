const task = @import("../../task.zig");

pub const Algorithm = struct {
    pub fn selectNext(_: Algorithm, _: []task.TCB, _: usize) usize {
        unreachable;
    }

    pub fn run(_: Algorithm, tasks: []task.TCB) noreturn {
        while (true) {
            for (tasks) |t| {
                t.entry();
            }
        }
    }
};
