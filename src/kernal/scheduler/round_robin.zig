const task = @import("../task.zig");

pub const RoundRobin = struct {
    pub fn selectNext(_: *RoundRobin, tasks: []task.TCB, current: usize) usize {
        return (current + 1) % tasks.len;
    }
};
