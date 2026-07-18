const task = @import("../task.zig");
const round_robin = @import("round_robin.zig");

pub const Policy = union(enum) {
    round_robin: round_robin.RoundRobin,

    pub fn selectNext(self: *Policy, tasks: []task.TCB, current: usize) usize {
        return switch (self.*) {
            inline else => |*implementation| implementation.selectNext(tasks, current),
        };
    }
};
