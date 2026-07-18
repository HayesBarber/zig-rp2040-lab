const task = @import("../task.zig");
const TCB = task.TCB;

pub fn initFullStackFrame(tcb: *TCB, task_exit_addr: usize) void {
    const stack_top = @intFromPtr(&tcb.stack) + TCB.STACK_SIZE;

    // Reserve:
    //   32 bytes for r4-r11 (saved by PendSV)
    //   32 bytes for hardware exception frame
    const sp = stack_top - 64;
    @as(*[8]u32, @ptrFromInt(sp)).* = .{
        0, 0, 0, 0, // r4-r7
        0, 0, 0, 0, // r8-r11
    };
    initHardwareStackFrame(tcb, task_exit_addr);
    tcb.sp = sp;
}

pub fn initHardwareStackFrame(tcb: *TCB, task_exit_addr: usize) void {
    const stack_top = @intFromPtr(&tcb.stack) + TCB.STACK_SIZE;
    const sp = stack_top - 32;

    const hw = @as(*[8]u32, @ptrFromInt(sp));
    hw.* = .{
        0, // R0
        0, // R1
        0, // R2
        0, // R3
        0, // R12
        task_exit_addr, // LR
        @intFromPtr(tcb.entry) | 1, // PC
        0x01000000, // xPSR (Thumb bit)
    };
    tcb.sp = sp;
}
