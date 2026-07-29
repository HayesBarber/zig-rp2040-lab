const scheduler = @import("../scheduler/mod.zig");
const core = @import("core");

pub fn handler() void {
    if (@hasDecl(scheduler.impl, "tick")) {
        if (scheduler.instance.tick()) {
            core.pendsv.request();
        }
    }
}
