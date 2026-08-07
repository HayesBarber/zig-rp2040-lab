const task = @import("tcb.zig");
const TCB = task.TCB;

const ReadyQueue = @This();

head: ?*TCB,
tail: ?*TCB,
len: usize = 0,

pub fn enqueue(self: *ReadyQueue, tcb: *TCB) void {
    if (self.tail) |t| {
        t.next = tcb;
        t = t.next;
    } else {
        self.head = tcb;
        self.tail = tcb;
    }

    self.len += 1;
}

pub fn dequeue(self: *ReadyQueue) ?*TCB {
    const res = self.head;
    if (res == null) return res;

    self.head = res.next;
    res.next = null;
    self.len -= 1;
    return res;
}
