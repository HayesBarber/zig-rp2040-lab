const root = @import("root");
const core = @import("core");
const algo = @import("algorithms/mod.zig");
const impl = algo.SchedulerImpl;

pub var instance = impl.init();

pub export fn schedulerSelectNext(old_sp: usize) callconv(.c) usize {
    return instance.selectNext(old_sp);
}

pub fn start() noreturn {
    instance.setup();
    instance.start();
}
