pub fn ReadyQueue(comptime T: type) type {
    if (!@hasField(T, "next") or @TypeOf(@field(@as(T, undefined), "next")) != ?*T) {
        @compileError("ReadyQueue requires a type with a field \"next\" of type ?*T");
    }

    return struct {
        const Self = @This();
        head: ?*T = null,
        tail: ?*T = null,
        len: usize = 0,

        pub fn enqueue(self: *Self, tcb: *T) void {
            if (self.tail != null) {
                self.tail.?.next = tcb;
                self.tail = self.tail.?.next;
            } else {
                self.head = tcb;
                self.tail = tcb;
            }

            self.len += 1;
        }

        pub fn dequeue(self: *Self) ?*T {
            const res = self.head;
            if (res == null) return res;

            self.head = res.?.next;
            res.?.next = null;
            self.len -= 1;
            return res;
        }
    };
}

const std = @import("std");
const expect = std.testing.expect;

const TestNode = struct {
    const Self = @This();

    next: ?*Self = null,
};

test "Create ReadyQueue" {
    const q: ReadyQueue(TestNode) = .{};
    try expect(q.len == 0);
    try expect(q.head == null);
    try expect(q.tail == null);
}

test "Enqueue" {
    var q: ReadyQueue(TestNode) = .{};
    var head: TestNode = .{};
    q.enqueue(&head);
    try expect(q.len == 1);
    try expect(q.head == &head);
    try expect(q.tail == &head);

    var tail: TestNode = .{};
    q.enqueue(&tail);
    try expect(q.len == 2);
    try expect(q.head == &head);
    try expect(q.tail == &tail);
}

test "Dequeue" {
    var q: ReadyQueue(TestNode) = .{};
    var head: TestNode = .{};
    q.enqueue(&head);
    try expect(q.len == 1);

    const popped = q.dequeue();
    try expect(q.len == 0);
    try expect(&head == popped);
}
