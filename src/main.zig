const core = @import("core");

comptime {
    @import("zrt0").init();
}

pub fn main() noreturn {
    while (true) {
        asm volatile ("wfi");
    }
}
