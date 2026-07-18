const scheduler = @import("../scheduler/mod.zig");
const pendsv = @import("../arch/armv6m/pendsv.zig");

pub fn handler() void {
    if (scheduler.tick()) {
        pendsv.request();
    }
}
