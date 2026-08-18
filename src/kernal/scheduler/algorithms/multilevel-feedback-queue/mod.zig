const root = @import("root");
const core = @import("core");
const heap = @import("../../../heap.zig");
const stack_frame = @import("../../../util/stack_frame.zig");
const SpinLock = @import("../../../mutual-exclusion/spin_lock.zig");
const MultilevelQueue = @import("multilevel_queue.zig").MultilevelQueue;
const tcb = @import("tcb.zig");
const TCB = tcb.TCB;

const LEVEL_COUNT = root.MLFQ_LEVEL_COUNT;
const TaskQueue = MultilevelQueue(TCB, LEVEL_COUNT);

var tasks: []TCB = &.{};
var ready_tasks: TaskQueue = .{};
const lock: SpinLock = .init(0);

const MultilevelFeedbackQueue = @This();
current_task: ?*TCB = null,

fn taskExit() noreturn {
    while (true) {
        core.pendsv.request();
        asm volatile ("wfi");
    }
}

fn registerTasks() void {
    const group = root.registerTasks();
    if (group.task_entries.len == 0) {
        @trap();
    }

    tasks = heap.allocator.alloc(TCB, group.task_entries.len) catch @trap();
    for (group.task_entries, 0..) |entry, index| {
        const task = &tasks[index];
        task.* = .{
            .name = entry.name,
            .entry = entry.entry,
            .exit = &taskExit,
        };
    }
}

pub fn init() MultilevelFeedbackQueue {
    return .{};
}

pub fn initShared(multicore: bool) void {
    registerTasks();
    core.watchdog.enable();

    tasks[0].sp = stack_frame.initHardwareStackFrame(
        &tasks[0].stack,
        TCB.STACK_SIZE,
        tasks[0].entry,
        tasks[0].exit,
    );

    const first_full_frame: usize = if (multicore) blk: {
        if (tasks.len < 2) @trap();
        tasks[1].sp = stack_frame.initHardwareStackFrame(
            &tasks[1].stack,
            TCB.STACK_SIZE,
            tasks[1].entry,
            tasks[1].exit,
        );
        break :blk 2;
    } else 1;
    for (tasks[first_full_frame..]) |*task| {
        task.sp = stack_frame.initFullStackFrame(
            &task.stack,
            TCB.STACK_SIZE,
            task.entry,
            task.exit,
        );
        ready_tasks.add(task);
    }

    // Reserve each core's first task before Core 1 is launched. This keeps
    // either core from selecting the other's initial PSP frame.
    for (tasks[0..first_full_frame]) |*task| {
        task.level = LEVEL_COUNT / 2;
        task.state = .Running;
    }
}

pub fn initCore(self: *MultilevelFeedbackQueue, core_id: usize, multicore: bool) void {
    const initial_task_index = if (multicore) core_id else 0;
    self.current_task = &tasks[initial_task_index];

    asm volatile (
        \\msr psp, %[p]
        :
        : [p] "r" (self.current_task.?.sp),
    );

    core.pendsv.setLowestPriority();
}

pub fn start(_: *MultilevelFeedbackQueue) noreturn {
    core.systick.init();
    taskExit();
}

pub fn selectNext(self: *MultilevelFeedbackQueue, old_sp: usize) usize {
    const guard = lock.acquire();
    defer guard.release();

    const current = self.current_task orelse @trap();
    current.sp = old_sp;
    if (current.state == .Running) {
        if (current.remaining_ticks == 0 and current.level < LEVEL_COUNT - 1) {
            current.level += 1;
        }
        current.state = .Ready;
        ready_tasks.enqueue(current);
    }

    const next = ready_tasks.dequeue() orelse current;
    next.state = .Running;
    next.remaining_ticks = next.quantum;
    self.current_task = next;
    return next.sp;
}

pub fn tick(self: *MultilevelFeedbackQueue) bool {
    core.watchdog.feed();
    const current = self.current_task orelse @trap();
    current.remaining_ticks -= 1;
    return current.remaining_ticks == 0;
}

pub fn blockCurrent(self: *MultilevelFeedbackQueue) *anyopaque {
    const current = self.current_task orelse @trap();
    current.state = .Blocked;
    return current;
}

pub fn makeReady(_: *MultilevelFeedbackQueue, task: *anyopaque) void {
    const guard = lock.acquire();
    defer guard.release();

    const ready_task: *TCB = @ptrCast(@alignCast(task));
    if (ready_task.state != .Blocked) return;

    if (ready_task.level > 0) ready_task.level -= 1;
    ready_task.state = .Ready;
    ready_tasks.enqueue(ready_task);
}
