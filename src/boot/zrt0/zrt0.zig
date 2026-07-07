const root = @import("root");

extern const __stack_top: u8;

pub const vector_table align(256) linksection(".vectors") = [_]usize{
    @intFromPtr(&__stack_top), // 0: Initial Stack Pointer
    @intFromPtr(&_start), // 1: Reset
    0, // 2: NMI
    0, // 3: HardFault
    0, // 4: MemManage
    0, // 5: BusFault
    0, // 6: UsageFault
    0, // 7: Reserved
    0, // 8: Reserved
    0, // 9: Reserved
    0, // 10: Reserved
    0, // 11: SVCall
    0, // 12: Reserved
    0, // 13: Reserved
    0, // 14: PendSV
    0, // 15: SysTick
};

export fn _start() callconv(.c) noreturn {
    root.main();

    while (true) {}
}

pub fn init() void {
    // builds boot2
    _ = @import("bootrom");
    @export(&vector_table, .{
        .name = "_vector_table",
        .section = ".vectors",
        .linkage = .strong,
    });
}
