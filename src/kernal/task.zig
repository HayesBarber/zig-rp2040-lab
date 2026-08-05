const root = @import("root");

pub const Entry = switch (root.SCHEDULER_ALGORITHM) {
    .super_loop => *const fn () void,
    .round_robin => *const fn () noreturn,
};

pub const TaskEntry = struct {
    name: []const u8,
    entry: Entry,
};

pub const TaskGroup = struct {
    task_entries: []const TaskEntry,
};
