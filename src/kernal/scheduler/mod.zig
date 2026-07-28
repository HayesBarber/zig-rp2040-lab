const root = @import("root");
const core = @import("core");
const rr = @import("algorithms/round_robin.zig");

pub var instance = rr.init();

pub export fn schedulerSelectNext(old_sp: usize) callconv(.c) usize {
    return instance.selectNext(old_sp);
}

pub fn start() noreturn {
    instance.setup();
    instance.start();
}
