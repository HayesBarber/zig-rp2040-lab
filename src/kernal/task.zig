pub const TaskEntry = struct {
    name: []const u8,
    entry: *const fn () noreturn,
};

pub const TaskGroup = struct {
    task_entries: []const TaskEntry,
};

pub const State = enum {
    Ready,
    Running,
    Blocked,
};

pub const TCB = struct {
    pub const STACK_SIZE = 1024;

    name: []const u8,
    entry: *const fn () noreturn,
    exit: *const fn () noreturn,
    state: State = .Ready,
    quantum: usize = 100,
    remaining_ticks: usize = 100,
    sp: usize = 0,
    stack: [STACK_SIZE]u8 align(8) = undefined,
};
