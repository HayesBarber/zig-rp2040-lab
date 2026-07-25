pub inline fn disable() void {
    asm volatile ("cpsid i");
}

pub inline fn enable() void {
    asm volatile ("cpsie i");
}
