const root = @import("root");
const core = @import("core");
const heap = @import("../../heap.zig");
const task = @import("../../task.zig");
const stack_frame = @import("../../util/stack_frame.zig");
const TCB = task.TCB;

var tasks: []TCB = &.{};

const RoundRobin = @This();
current_task_idx: usize,

fn taskExit() noreturn {
    while (true) {
        core.pendsv.request();
        asm volatile ("wfi");
    }
}

fn registerTasks(_: *RoundRobin) void {
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

pub fn setup(self: *RoundRobin) void {
    self.registerTasks();
    core.watchdog.enable();
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
}

pub fn init() RoundRobin {
    return .{
        .current_task_idx = 0,
    };
}

pub fn start(_: *RoundRobin) noreturn {
    core.systick.init();
    taskExit();
}

pub fn selectNext(self: *RoundRobin, old_sp: usize) usize {
    tasks[self.current_task_idx].sp = old_sp;
    if (tasks[self.current_task_idx].state == .Running) {
        tasks[self.current_task_idx].state = .Ready;
    }

    for (0..tasks.len) |offset| {
        const candidate = (self.current_task_idx + offset + 1) % tasks.len;
        if (tasks[candidate].state != .Blocked) {
            self.current_task_idx = candidate;
            break;
        }
    }

    tasks[self.current_task_idx].state = .Running;
    tasks[self.current_task_idx].remaining_ticks = tasks[self.current_task_idx].quantum;
    return tasks[self.current_task_idx].sp;
}

pub fn tick(self: *RoundRobin) bool {
    core.watchdog.feed();
    tasks[self.current_task_idx].remaining_ticks -= 1;
    return tasks[self.current_task_idx].remaining_ticks == 0;
}

pub fn blockCurrent(self: *RoundRobin) *TCB {
    const current = &tasks[self.current_task_idx];
    current.state = .Blocked;
    core.pendsv.request();
    return current;
}

pub fn makeReady(_: *RoundRobin, t: *TCB) void {
    if (t.state == .Blocked) t.state = .Ready;
}
