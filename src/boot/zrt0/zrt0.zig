const root = @import("root");

comptime {
    _ = @import("bootrom");
}

export fn _start() callconv(.c) noreturn {
    root.main();

    while (true) {
        asm volatile ("" ::: .{ .memory = true });
    }
}
