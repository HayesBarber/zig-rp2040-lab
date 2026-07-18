const root = @import("root");
const task = @import("../task.zig");
const stack_frame = @import("../util/stack_frame.zig");
const armv6m = @import("../arch/armv6m/mod.zig");
const algorithm = @import("round_robin.zig");

var tasks = blk: {
    const group = root.setup();
    var entries: [group.task_entries.len]task.TCB = undefined;
    for (&entries, group.task_entries) |*t, e| {
        t.* = .{
            .name = e.name,
            .entry = e.entry,
            .exit = &taskExit,
        };
    }
    break :blk entries;
};
var current_task_idx: usize = 0;
var active_algorithm: algorithm.Algorithm = .{};

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

    const next = active_algorithm.selectNext(&tasks, current_task_idx);
    current_task_idx = next;

    tasks[next].state = .Running;
    tasks[next].remaining_ticks = tasks[next].quantum;
    return tasks[next].sp;
}

pub fn start() noreturn {
    stack_frame.initHardwareStackFrame(&tasks[0]);
    for (tasks[1..]) |*t| {
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
