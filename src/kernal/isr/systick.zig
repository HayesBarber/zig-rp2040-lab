const scheduler = @import("../scheduler/mod.zig");
const core = @import("core");

pub fn handler() void {
    if (scheduler.tick()) {
        core.pendsv.request();
    }
}
