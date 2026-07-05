comptime {
    _ = @import("zrt0");
    _ = @import("bootrom");
}

pub fn main() noreturn {
    while (true) {
        asm volatile ("" ::: .{ .memory = true });
    }
}
