const zrt0 = @import("zrt0");

comptime {
    zrt0.init();
}

pub fn main() noreturn {
    while (true) {
        asm volatile ("" ::: .{ .memory = true });
    }
}
