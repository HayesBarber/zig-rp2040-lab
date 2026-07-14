const root = @import("root");
const core = @import("core");
const kernal = @import("kernal");

comptime {
    _ = @import("bootrom");
}

extern const __stack_top: u8;

const VectorTable = extern struct {
    initial_sp: *const anyopaque,
    reset: *const fn () callconv(.c) noreturn,
    nmi: ?*const anyopaque = null,
    hard_fault: ?*const anyopaque = null,
    reserved0: ?*const anyopaque = null,
    reserved1: ?*const anyopaque = null,
    reserved2: ?*const anyopaque = null,
    reserved3: ?*const anyopaque = null,
    reserved4: ?*const anyopaque = null,
    reserved5: ?*const anyopaque = null,
    reserved6: ?*const anyopaque = null,
    svcall: ?*const anyopaque = null,
    reserved7: ?*const anyopaque = null,
    reserved8: ?*const anyopaque = null,
    pendsv: ?*const anyopaque = null,
    systick: ?*const anyopaque = null,
};

export const vector_table align(256) linksection(".vectors") = VectorTable{
    .initial_sp = &__stack_top,
    .reset = &_start,
    .systick = &kernal.scheduler.sysTickISR,
};

fn copy_data_and_bss() void {
    const sections = struct {
        extern var zrt_data_start: anyopaque;
        extern var zrt_data_end: anyopaque;
        extern var zrt_bss_start: anyopaque;
        extern var zrt_bss_end: anyopaque;
        extern const zrt_data_load_start: anyopaque;
    };

    const bss_start: [*]u8 = @ptrCast(&sections.zrt_bss_start);
    const bss_end: [*]u8 = @ptrCast(&sections.zrt_bss_end);
    const bss_len = @intFromPtr(bss_end) - @intFromPtr(bss_start);
    @memset(bss_start[0..bss_len], 0);

    const data_start: [*]u8 = @ptrCast(&sections.zrt_data_start);
    const data_end: [*]u8 = @ptrCast(&sections.zrt_data_end);
    const data_len = @intFromPtr(data_end) - @intFromPtr(data_start);
    const data_src: [*]const u8 = @ptrCast(&sections.zrt_data_load_start);
    @memcpy(data_start[0..data_len], data_src[0..data_len]);
}

export fn _start() callconv(.c) noreturn {
    copy_data_and_bss();

    core.gpio.resetIOBank0();
    core.gpio.ledInit();
    core.clocks.initClocks();
    core.uart.initUart();
    kernal.scheduler.start();
    root.main();
    while (true) {
        asm volatile ("wfi");
    }
}

pub fn init() void {}
