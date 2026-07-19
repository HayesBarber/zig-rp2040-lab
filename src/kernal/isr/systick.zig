const scheduler = @import("../scheduler/mod.zig");
const core = @import("core");

pub fn handler() void {
    core.watchdog.feed();
    if (scheduler.tick()) {
        core.pendsv.request();
    }
}
