const task = @import("../task.zig");

pub const Algorithm = struct {
    pub fn selectNext(_: *Algorithm, tasks: []task.TCB, current: usize) usize {
        return (current + 1) % tasks.len;
    }
};
