const root = @import("root");

extern const __stack_top: u8;

pub const VectorTable = extern struct {
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
};

export fn _start() callconv(.c) noreturn {
    root.main();

    while (true) {}
}

pub fn init() void {
    _ = @import("bootrom");
}
