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
            if (self.head == null) self.tail = null;
            return res;
        }

        /// Remove a specific node while preserving the order of all others.
        pub fn remove(self: *Self, tcb: *T) bool {
            var previous: ?*T = null;
            var current = self.head;
            while (current) |node| : (current = node.next) {
                if (node != tcb) {
                    previous = node;
                    continue;
                }

                if (previous) |prev| {
                    prev.next = node.next;
                } else {
                    self.head = node.next;
                }
                if (self.tail == node) self.tail = previous;
                node.next = null;
                self.len -= 1;
                return true;
            }
            return false;
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

test "enqueue appends nodes and preserves FIFO links" {
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
    try expect(head.next == &tail);
    try expect(tail.next == null);
}

test "dequeue returns null from an empty queue" {
    var q: ReadyQueue(TestNode) = .{};

    try expect(q.dequeue() == null);
    try expect(q.len == 0);
    try expect(q.head == null);
    try expect(q.tail == null);
}

test "dequeue returns nodes in FIFO order and clears their links" {
    var q: ReadyQueue(TestNode) = .{};
    var first: TestNode = .{};
    var second: TestNode = .{};
    var third: TestNode = .{};
    q.enqueue(&first);
    q.enqueue(&second);
    q.enqueue(&third);

    try expect(q.dequeue() == &first);
    try expect(first.next == null);
    try expect(q.len == 2);
    try expect(q.head == &second);
    try expect(q.tail == &third);

    try expect(q.dequeue() == &second);
    try expect(second.next == null);
    try expect(q.len == 1);
    try expect(q.head == &third);
    try expect(q.tail == &third);

    try expect(q.dequeue() == &third);
    try expect(third.next == null);
    try expect(q.len == 0);
    try expect(q.head == null);
    try expect(q.tail == null);
}

test "queue accepts enqueues after it is drained" {
    var q: ReadyQueue(TestNode) = .{};
    var first: TestNode = .{};
    var second: TestNode = .{};

    q.enqueue(&first);
    try expect(q.dequeue() == &first);

    q.enqueue(&second);
    try expect(q.len == 1);
    try expect(q.head == &second);
    try expect(q.tail == &second);
    try expect(q.dequeue() == &second);
    try expect(q.len == 0);
}

test "remove unlinks a specific node and preserves the remaining FIFO order" {
    var q: ReadyQueue(TestNode) = .{};
    var first: TestNode = .{};
    var middle: TestNode = .{};
    var last: TestNode = .{};
    var absent: TestNode = .{};
    q.enqueue(&first);
    q.enqueue(&middle);
    q.enqueue(&last);

    try expect(q.remove(&middle));
    try expect(middle.next == null);
    try expect(q.len == 2);
    try expect(q.head == &first);
    try expect(q.tail == &last);
    try expect(first.next == &last);
    try expect(!q.remove(&absent));

    try expect(q.remove(&first));
    try expect(q.head == &last);
    try expect(q.tail == &last);
    try expect(q.remove(&last));
    try expect(q.len == 0);
    try expect(q.head == null);
    try expect(q.tail == null);
}
