pub fn initFullStackFrame(
    stack_bottom: *anyopaque,
    stack_size: comptime_int,
    entry: *const fn () noreturn,
    exit: *const fn () noreturn,
) usize {
    const stack_top = @intFromPtr(stack_bottom) + stack_size;

    // Reserve:
    //   32 bytes for r4-r11 (saved by PendSV)
    //   32 bytes for hardware exception frame
    const sp = stack_top - 64;
    @as(*[8]u32, @ptrFromInt(sp)).* = .{
        0, 0, 0, 0, // r4-r7
        0, 0, 0, 0, // r8-r11
    };
    _ = initHardwareStackFrame(stack_bottom, stack_size, entry, exit);
    return sp;
}

pub fn initHardwareStackFrame(
    stack_bottom: *anyopaque,
    stack_size: comptime_int,
    entry: *const fn () noreturn,
    exit: *const fn () noreturn,
) usize {
    const stack_top = @intFromPtr(stack_bottom) + stack_size;
    const sp = stack_top - 32;

    const hw = @as(*[8]u32, @ptrFromInt(sp));
    hw.* = .{
        0, // R0
        0, // R1
        0, // R2
        0, // R3
        0, // R12
        @intFromPtr(exit) | 1, // LR
        @intFromPtr(entry) | 1, // PC
        0x01000000, // xPSR (Thumb bit)
    };
    return sp;
}
