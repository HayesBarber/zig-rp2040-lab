pub inline fn disable() void {
    asm volatile ("cpsid i");
}

pub inline fn enable() void {
    asm volatile ("cpsie i");
}

pub inline fn saveAndDisable() u32 {
    return asm volatile (
        \\mrs %[mask], primask
        \\cpsid i
        : [mask] "=r" (-> u32),
    );
}

pub inline fn restore(mask: u32) void {
    asm volatile ("msr primask, %[mask]"
        :
        : [mask] "r" (mask),
    );
}
