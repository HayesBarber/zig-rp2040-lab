const root = @import("root");
pub const Algorithm = enum { super_loop, round_robin };

pub const SchedulerImpl = switch (root.SCHEDULER_ALGORITHM) {
    .round_robin => @import("round_robin.zig"),
    .super_loop => @import("super_loop.zig"),
};
