const task = @import("../../task.zig");

pub const Algorithm = struct {
    pub fn selectNext(_: Algorithm, tasks: []task.TCB, current: usize) usize {
        for (0..tasks.len) |offset| {
            const candidate = (current + offset + 1) % tasks.len;
            if (tasks[candidate].state != .Blocked) return candidate;
        }
        @trap();
    }
};
