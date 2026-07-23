const std = @import("std");

extern const __heap_start: u8;
extern const __heap_end: u8;

var fba: std.heap.FixedBufferAllocator = undefined;
pub var allocator: std.mem.Allocator = undefined;

pub fn init() void {
    const start = @intFromPtr(&__heap_start);
    const end = @intFromPtr(&__heap_end);
    const buf: []u8 = @as([*]u8, @ptrCast(@constCast(&__heap_start)))[0 .. end - start];
    fba = std.heap.FixedBufferAllocator.init(buf);
    allocator = fba.allocator();
}
