const Algorithm = enum { super_loop, round_robin };
const selected = Algorithm.round_robin;

pub const SchedulerImpl = switch (selected) {
    .round_robin => @import("round_robin.zig"),
    .super_loop => @import("super_loop.zig"),
};
