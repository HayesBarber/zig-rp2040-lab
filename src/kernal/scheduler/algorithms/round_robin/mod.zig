const root = @import("root");
const core = @import("core");
const heap = @import("../../../heap.zig");
const stack_frame = @import("../../../util/stack_frame.zig");
const SpinLock = @import("../../../mutual-exclusion/spin_lock.zig");
const tcb = @import("tcb.zig");
const TCB = tcb.TCB;

var tasks: []TCB = &.{};
const lock: SpinLock = .init(0);

const RoundRobin = @This();
current_task_idx: usize,

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
        const t = &tasks[index];
        t.* = .{
            .name = entry.name,
            .entry = entry.entry,
            .exit = &taskExit,
        };
    }
}

pub fn init() RoundRobin {
    return .{
        .current_task_idx = 0,
    };
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
    for (tasks[first_full_frame..]) |*t| {
        t.sp = stack_frame.initFullStackFrame(
            &t.stack,
            TCB.STACK_SIZE,
            t.entry,
            t.exit,
        );
    }

    // Reserve each core's first task before Core 1 is launched. This keeps
    // either core from selecting the other's initial PSP frame.
    for (tasks[0..first_full_frame]) |*t| {
        t.state = .Running;
    }
}

pub fn initCore(self: *RoundRobin, core_id: usize, multicore: bool) void {
    self.current_task_idx = if (multicore) core_id else 0;

    asm volatile (
        \\msr psp, %[p]
        :
        : [p] "r" (tasks[self.current_task_idx].sp),
    );

    core.pendsv.setLowestPriority();
}

pub fn start(_: *RoundRobin) noreturn {
    core.systick.init();
    taskExit();
}

pub fn selectNext(self: *RoundRobin, old_sp: usize) usize {
    const guard = lock.acquire();
    defer guard.release();

    tasks[self.current_task_idx].sp = old_sp;
    if (tasks[self.current_task_idx].state == .Running) {
        tasks[self.current_task_idx].state = .Ready;
    }

    for (0..tasks.len) |offset| {
        const candidate = (self.current_task_idx + offset + 1) % tasks.len;
        if (tasks[candidate].state == .Ready) {
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

pub fn blockCurrent(self: *RoundRobin) *anyopaque {
    const current = &tasks[self.current_task_idx];
    current.state = .Blocked;
    return current;
}

pub fn makeReady(_: *RoundRobin, task: *anyopaque) void {
    var t: *TCB = @ptrCast(@alignCast(task));
    if (t.state == .Blocked) t.state = .Ready;
}
