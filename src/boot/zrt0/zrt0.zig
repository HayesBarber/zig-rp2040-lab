const root = @import("root");

pub export fn _start() callconv(.c) noreturn {
    root.main();
}
