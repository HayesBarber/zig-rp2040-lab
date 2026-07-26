const root = @import("root");
const core = @import("core");
const heap = @import("../heap.zig");
const task = @import("../task.zig");
const stack_frame = @import("../util/stack_frame.zig");
const algorithms = @import("algorithms/mod.zig");

var tasks: []task.TCB = &.{};
var current_task_idx: usize = 0;
const active_algorithm = algorithms.selected;

fn registerTasks() void {
    const group = root.registerTasks();
    if (group.task_entries.len == 0) {
        @trap();
    }

    tasks = heap.allocator.alloc(task.TCB, group.task_entries.len) catch @trap();

    for (group.task_entries, 0..) |entry, index| {
        const t = &tasks[index];
        t.* = .{
            .name = entry.name,
            .entry = entry.entry,
            .exit = &taskExit,
        };
    }
}

pub fn tick() bool {
    tasks[current_task_idx].remaining_ticks -= 1;
    return tasks[current_task_idx].remaining_ticks == 0;
}

pub fn blockCurrent() *task.TCB {
    const current = &tasks[current_task_idx];
    current.state = .Blocked;
    core.pendsv.request();
    return current;
}

pub fn makeReady(t: *task.TCB) void {
    if (t.state == .Blocked) t.state = .Ready;
}

fn taskExit() noreturn {
    while (true) {
        core.pendsv.request();
        asm volatile ("wfi");
    }
}

pub export fn schedulerSelectNext(old_sp: usize) callconv(.c) usize {
    tasks[current_task_idx].sp = old_sp;
    if (tasks[current_task_idx].state == .Running) {
        tasks[current_task_idx].state = .Ready;
    }

    const next = active_algorithm.selectNext(tasks, current_task_idx);
    current_task_idx = next;

    tasks[next].state = .Running;
    tasks[next].remaining_ticks = tasks[next].quantum;
    return tasks[next].sp;
}

pub fn start() noreturn {
    registerTasks();

    core.watchdog.enable();

    if (!active_algorithm.requiresContextSwitch()) {
        active_algorithm.run(tasks);
    }

    stack_frame.initHardwareStackFrame(&tasks[0]);
    for (tasks[1..]) |*t| {
        stack_frame.initFullStackFrame(t);
    }

    asm volatile (
        \\msr psp, %[p]
        :
        : [p] "r" (tasks[0].sp),
    );

    core.pendsv.setLowestPriority();
    core.systick.init();
    taskExit();
}
