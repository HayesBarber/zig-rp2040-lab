const mmio = @import("mmio.zig");

pub fn microseconds() u64 {
    var high = mmio.timer.timerawh;
    while (true) {
        const low = mmio.timer.timerawl;
        const next_high = mmio.timer.timerawh;
        if (high == next_high) {
            return (@as(u64, high) << 32) | low;
        }
        high = next_high;
    }
}

pub fn milliseconds() u64 {
    return microseconds() / 1_000;
}
