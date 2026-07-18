const task = @import("../../task.zig");
const round_robin = @import("round_robin.zig");
const super_loop = @import("super_loop.zig");

pub const Algorithm = union(enum) {
    round_robin: round_robin.Algorithm,
    super_loop: super_loop.Algorithm,

    pub fn requiresContextSwitch(self: Algorithm) bool {
        return switch (self) {
            .super_loop => false,
            else => true,
        };
    }

    pub fn selectNext(self: Algorithm, tasks: []task.TCB, current: usize) usize {
        return switch (self) {
            inline else => |implementation| implementation.selectNext(tasks, current),
        };
    }

    pub fn run(self: Algorithm, tasks: []task.TCB) noreturn {
        return switch (self) {
            .super_loop => |implementation| implementation.run(tasks),
            else => unreachable,
        };
    }
};

pub const selected: Algorithm = .{ .round_robin = .{} };
