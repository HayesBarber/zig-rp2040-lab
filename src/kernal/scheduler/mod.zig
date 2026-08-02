const root = @import("root");
const core = @import("core");
const algo = @import("algorithms/mod.zig");

pub const impl = algo.SchedulerImpl;
pub const mode: @TypeOf(root.SCHEDULER_MODE) = root.SCHEDULER_MODE;

var instances = [_]impl{ impl.init(), impl.init() };

fn currentCoreId() usize {
    return @as(usize, core.multicore.coreId());
}

pub fn currentInstance() *impl {
    return &instances[currentCoreId()];
}

pub export fn schedulerSelectNext(old_sp: usize) callconv(.c) usize {
    if (!@hasDecl(impl, "selectNext")) unreachable;
    return currentInstance().selectNext(old_sp);
}

pub fn tick() bool {
    if (!@hasDecl(impl, "tick")) return false;
    return currentInstance().tick();
}

pub fn blockCurrent() *anyopaque {
    if (!@hasDecl(impl, "blockCurrent")) {
        @compileError("Chosen scheduler implementation has no ability to block a task");
    }
    return currentInstance().blockCurrent();
}

pub fn makeReady(task: *anyopaque) void {
    if (!@hasDecl(impl, "makeReady")) return;
    currentInstance().makeReady(task);
}

pub fn start() noreturn {
    if (@hasDecl(impl, "initShared")) {
        impl.initShared(mode == .multi_core);
    }

    initializeCore(0);

    if (mode == .multi_core) {
        core.multicore.launchCore1(&startCore1);
    }

    instances[0].start();
}

fn startCore1() noreturn {
    initializeCore(1);
    instances[1].start();
}

fn initializeCore(core_id: usize) void {
    if (@hasDecl(impl, "initCore")) {
        instances[core_id].initCore(core_id, mode == .multi_core);
    }
}
