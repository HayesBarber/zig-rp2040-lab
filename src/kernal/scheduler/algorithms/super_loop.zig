const root = @import("root");
const heap = @import("../../heap.zig");
const task = @import("../../task.zig");
const TCB = task.TCB;

var tasks: []TCB = &.{};

const SuperLoop = @This();

fn taskExit() noreturn {
    while (true) {
        asm volatile ("nop");
    }
}

fn registerTasks(_: *SuperLoop) void {
    const group = root.registerTasks();
    if (group.task_entries.len == 0) {
        @trap();
    }

    tasks = heap.allocator.alloc(TCB, group.task_entries.len) catch @trap();

    for (group.task_entries, 0..) |entry, index| {
        const t = &tasks[index];
        t.* = .{
            .name = entry.name,
            .entry = entry.entry,
            .exit = &taskExit,
        };
    }
}

pub fn setup(self: *SuperLoop) void {
    self.registerTasks();
}

pub fn init() SuperLoop {
    return .{};
}

pub fn start(_: *SuperLoop) noreturn {
    while (true) {
        for (tasks) |t| {
            t.entry();
        }
    }
}

pub fn tick(_: *SuperLoop) bool {
    unreachable;
}

pub fn blockCurrent(_: *SuperLoop) *TCB {
    unreachable;
}

pub fn makeReady(_: *SuperLoop, _: *TCB) void {
    unreachable;
}
