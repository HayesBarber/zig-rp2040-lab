const root = @import("root");
const task = @import("../../../task.zig");
const TaskGroup = task.TaskGroup;

const tasks: TaskGroup = root.registerTasks();

const SuperLoop = @This();

start_index: usize = 0,
end_index: usize = tasks.task_entries.len,

pub fn init() SuperLoop {
    return .{};
}

pub fn initShared(_: bool) void {}

pub fn initCore(self: *SuperLoop, core_id: usize, multicore: bool) void {
    if (!multicore) return;

    const midpoint = (tasks.task_entries.len + 1) / 2;
    if (core_id == 0) {
        self.start_index = 0;
        self.end_index = midpoint;
    } else {
        self.start_index = midpoint;
        self.end_index = tasks.task_entries.len;
    }
}

pub fn start(self: *SuperLoop) noreturn {
    while (true) {
        for (tasks.task_entries[self.start_index..self.end_index]) |t| {
            t.entry();
        }
    }
}
