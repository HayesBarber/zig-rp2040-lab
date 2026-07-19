const scheduler = @import("../scheduler/mod.zig");
const pendsv = @import("../arch/armv6m/pendsv.zig");
const core = @import("core");

pub fn handler() void {
    core.watchdog.feed();
    if (scheduler.tick()) {
        pendsv.request();
    }
}
