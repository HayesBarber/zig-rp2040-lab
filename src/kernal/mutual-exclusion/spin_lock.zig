const core = @import("core");

const SpinLock = @This();

lock_num: u5,

pub fn init(comptime lock_num: u5) SpinLock {
    return .{
        .lock_num = lock_num,
    };
}

pub inline fn try_lock(self: *const SpinLock) bool {
    return core.mmio.spin_locks.locks[self.lock_num] != 0;
}

pub fn lock(self: *const SpinLock) void {
    while (!self.try_lock()) {}
}

pub fn unlock(self: *const SpinLock) void {
    core.mmio.spin_locks.locks[self.lock_num] = 0;
}
