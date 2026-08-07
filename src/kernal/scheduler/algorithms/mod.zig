const root = @import("root");
pub const Algorithm = enum { super_loop, round_robin, multilevel_feedback_queue };

pub const SchedulerImpl = switch (root.SCHEDULER_ALGORITHM) {
    .round_robin => @import("round_robin/mod.zig"),
    .super_loop => @import("super_loop/mod.zig"),
    .multilevel_feedback_queue => @import("multilevel-feedback-queue/mod.zig"),
};
