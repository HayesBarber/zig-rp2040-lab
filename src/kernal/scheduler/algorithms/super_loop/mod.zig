const root = @import("root");
const task = @import("../../../task.zig");
const TaskGroup = task.TaskGroup;

const tasks: TaskGroup = root.registerTasks();

const SuperLoop = @This();

pub fn init() SuperLoop {
    return .{};
}

pub fn setup(_: *SuperLoop) void {}

pub fn start(_: *SuperLoop) noreturn {
    while (true) {
        for (tasks.task_entries) |t| {
            t.entry();
        }
    }
}

pub fn selectNext(_: *SuperLoop, _: usize) usize {
    unreachable;
}

pub fn tick(_: *SuperLoop) bool {
    unreachable;
}

pub fn blockCurrent(_: *SuperLoop) *anyopaque {
    unreachable;
}

pub fn makeReady(_: *SuperLoop, _: *anyopaque) void {
    unreachable;
}
