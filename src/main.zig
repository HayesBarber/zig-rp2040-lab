comptime {
    _ = @import("zrt0");
}

pub fn main() noreturn {
    while (true) {
        asm volatile ("" ::: .{ .memory = true });
    }
}
