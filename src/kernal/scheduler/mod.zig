const root = @import("root");
const task = @import("../task.zig");
const stack_frame = @import("../util/stack_frame.zig");
const armv6m = @import("../arch/armv6m/mod.zig");
const algorithm = @import("round_robin.zig");

pub const MAX_TASKS = 8;

var tasks: [MAX_TASKS]task.TCB = undefined;
var task_count: usize = 0;
var current_task_idx: usize = 0;
var active_algorithm: algorithm.Algorithm = .{};

fn registerTasks() void {
    const group = root.registerTasks();
    if (group.task_entries.len == 0 or group.task_entries.len > MAX_TASKS) {
        @trap();
    }

    for (group.task_entries, 0..) |entry, index| {
        const t = &tasks[index];
        t.* = .{
            .name = entry.name,
            .entry = entry.entry,
            .exit = &taskExit,
        };
    }
    task_count = group.task_entries.len;
}

pub fn tick() bool {
    tasks[current_task_idx].remaining_ticks -= 1;
    return tasks[current_task_idx].remaining_ticks == 0;
}

fn taskExit() noreturn {
    while (true) {
        armv6m.pendsv.request();
        asm volatile ("wfi");
    }
}

pub export fn schedulerSelectNext(old_sp: usize) callconv(.c) usize {
    tasks[current_task_idx].sp = old_sp;
    tasks[current_task_idx].state = .Ready;

    const next = active_algorithm.selectNext(tasks[0..task_count], current_task_idx);
    current_task_idx = next;

    tasks[next].state = .Running;
    tasks[next].remaining_ticks = tasks[next].quantum;
    return tasks[next].sp;
}

pub fn start() noreturn {
    registerTasks();

    const registered_tasks = tasks[0..task_count];
    stack_frame.initHardwareStackFrame(&registered_tasks[0]);
    for (registered_tasks[1..]) |*t| {
        stack_frame.initFullStackFrame(t);
    }

    asm volatile (
        \\msr psp, %[p]
        :
        : [p] "r" (tasks[0].sp),
    );

    armv6m.pendsv.setLowestPriority();
    armv6m.systick.init();
    taskExit();
}
