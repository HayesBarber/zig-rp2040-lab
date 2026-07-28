pub const TaskEntry = struct {
    name: []const u8,
    entry: *const fn () noreturn,
};

pub const TaskGroup = struct {
    task_entries: []const TaskEntry,
};
