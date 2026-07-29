const root = @import("root");
const task = @import("../../../task.zig");
const TaskGroup = task.TaskGroup;

const tasks: TaskGroup = root.registerTasks();

const SuperLoop = @This();

pub fn init() SuperLoop {
    return .{};
}

pub fn start(_: *SuperLoop) noreturn {
    while (true) {
        for (tasks.task_entries) |t| {
            t.entry();
        }
    }
}
