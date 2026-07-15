pub const State = enum {
    Ready,
    Running,
    Blocked,
};

pub const Task = struct {
    name: []const u8,
    entry: *const fn () void,
    state: State,
};
