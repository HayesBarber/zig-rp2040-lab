const scheduler = @import("../scheduler/mod.zig");
const core = @import("core");

pub fn handler() void {
    if (scheduler.instance.tick()) {
        core.pendsv.request();
    }
}
