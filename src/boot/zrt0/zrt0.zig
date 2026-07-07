const root = @import("root");

extern const __stack_top: u8;

pub const VectorTable = extern struct {
    initial_sp: *const anyopaque,
    reset: *const fn () callconv(.c) noreturn,
    nmi: ?*const anyopaque,
    hard_fault: ?*const anyopaque,
    reserved0: ?*const anyopaque,
    reserved1: ?*const anyopaque,
    reserved2: ?*const anyopaque,
    reserved3: ?*const anyopaque,
    reserved4: ?*const anyopaque,
    reserved5: ?*const anyopaque,
    reserved6: ?*const anyopaque,
    svcall: ?*const anyopaque,
    reserved7: ?*const anyopaque,
    reserved8: ?*const anyopaque,
    pendsv: ?*const anyopaque,
    systick: ?*const anyopaque,
};

export const vector_table align(256) linksection(".vectors") = VectorTable{
    .initial_sp = &__stack_top,
    .reset = &_start,
    .nmi = null,
    .hard_fault = null,
    .reserved0 = null,
    .reserved1 = null,
    .reserved2 = null,
    .reserved3 = null,
    .reserved4 = null,
    .reserved5 = null,
    .reserved6 = null,
    .svcall = null,
    .reserved7 = null,
    .reserved8 = null,
    .pendsv = null,
    .systick = null,
};

export fn _start() callconv(.c) noreturn {
    root.main();

    while (true) {}
}

pub fn init() void {
    _ = @import("bootrom");
}
