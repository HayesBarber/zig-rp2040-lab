const root = @import("root");
const core = @import("core");
const algo = @import("algorithms/mod.zig");
pub const impl = algo.SchedulerImpl;

pub var instance = impl.init();

pub export fn schedulerSelectNext(old_sp: usize) callconv(.c) usize {
    if (!@hasDecl(impl, "selectNext")) {
        unreachable;
    }

    return instance.selectNext(old_sp);
}

pub fn start() noreturn {
    if (@hasDecl(impl, "setup")) {
        instance.setup();
    }
    instance.start();
}
