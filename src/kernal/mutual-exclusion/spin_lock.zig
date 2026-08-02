const core = @import("core");

const SpinLock = @This();

lock_num: u5,

pub fn init(comptime lock_num: u5) SpinLock {
    if (lock_num >= 32) {
        @compileError("There are only 32 spinlocks on the RP2040");
    }
    return .{
        .lock_num = lock_num,
    };
}

pub inline fn try_lock(self: *const SpinLock) bool {
    return core.mmio.spin_locks.locks[self.lock_num] != 0;
}

pub const Guard = struct {
    lock_ref: *const SpinLock,
    interrupt_mask: u32,

    pub fn release(self: Guard) void {
        self.lock_ref.unlock();
        core.interrupts.restore(self.interrupt_mask);
    }
};

pub fn acquire(self: *const SpinLock) Guard {
    const interrupt_mask = core.interrupts.saveAndDisable();
    while (!self.try_lock()) {}
    return .{
        .lock_ref = self,
        .interrupt_mask = interrupt_mask,
    };
}

pub fn unlock(self: *const SpinLock) void {
    core.mmio.spin_locks.locks[self.lock_num] = 0;
}
