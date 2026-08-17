const ReadyQueue = @import("ready_queue.zig").ReadyQueue;

/// A strict-priority collection of FIFO ready queues.
///
/// `T` must provide the intrusive link required by `ReadyQueue` plus a `level`
/// field. Level zero is the highest priority.
pub fn MultilevelQueue(comptime T: type, comptime level_count: usize) type {
    if (level_count == 0) {
        @compileError("MultilevelQueue requires at least one level");
    }
    if (!@hasField(T, "level") or @TypeOf(@field(@as(T, undefined), "level")) != usize) {
        @compileError("MultilevelQueue requires a type with a field \"level\" of type usize");
    }

    const Queue = ReadyQueue(T);

    return struct {
        const Self = @This();

        queues: [level_count]Queue = [_]Queue{.{}} ** level_count,

        /// Add a new task at the middle priority level.
        pub fn add(self: *Self, task: *T) bool {
            if (self.contains(task)) return false;

            task.level = level_count / 2;
            self.queues[task.level].enqueue(task);
            return true;
        }

        /// Requeue a task at its previously assigned priority level.
        pub fn enqueue(self: *Self, task: *T) bool {
            if (task.level >= level_count or self.contains(task)) return false;

            self.queues[task.level].enqueue(task);
            return true;
        }

        /// Return the next task from the highest non-empty priority level.
        pub fn dequeue(self: *Self) ?*T {
            for (&self.queues) |*queue| {
                if (queue.dequeue()) |task| return task;
            }
            return null;
        }

        /// Move a queued task one level toward the highest priority.
        pub fn promote(self: *Self, task: *T) bool {
            if (task.level >= level_count or task.level == 0) return false;
            return self.move(task, task.level - 1);
        }

        /// Move a queued task one level toward the lowest priority.
        pub fn demote(self: *Self, task: *T) bool {
            if (task.level >= level_count or task.level == level_count - 1) return false;
            return self.move(task, task.level + 1);
        }

        fn move(self: *Self, task: *T, destination_level: usize) bool {
            const source_level = task.level;
            if (!self.queues[source_level].remove(task)) return false;

            task.level = destination_level;
            self.queues[destination_level].enqueue(task);
            return true;
        }

        fn contains(self: *const Self, task: *const T) bool {
            for (self.queues) |queue| {
                var current = queue.head;
                while (current) |node| : (current = node.next) {
                    if (node == task) return true;
                }
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
    level: usize = 0,
};

test "add initializes tasks at the middle priority level" {
    var one_level: MultilevelQueue(TestNode, 1) = .{};
    var only: TestNode = .{ .level = 99 };
    try expect(one_level.add(&only));
    try expect(only.level == 0);
    try expect(one_level.queues[0].head == &only);

    var even_levels: MultilevelQueue(TestNode, 4) = .{};
    var even: TestNode = .{};
    try expect(even_levels.add(&even));
    try expect(even.level == 2);

    var odd_levels: MultilevelQueue(TestNode, 5) = .{};
    var odd: TestNode = .{};
    try expect(odd_levels.add(&odd));
    try expect(odd.level == 2);
}

test "dequeue uses strict priority and FIFO within a level" {
    var queue: MultilevelQueue(TestNode, 3) = .{};
    var first_low: TestNode = .{ .level = 2 };
    var high: TestNode = .{ .level = 0 };
    var second_low: TestNode = .{ .level = 2 };

    try expect(queue.enqueue(&first_low));
    try expect(queue.enqueue(&high));
    try expect(queue.enqueue(&second_low));

    try expect(queue.dequeue() == &high);
    try expect(queue.dequeue() == &first_low);
    try expect(queue.dequeue() == &second_low);
    try expect(queue.dequeue() == null);
}

test "promote relocates a queued task and preserves destination FIFO order" {
    var queue: MultilevelQueue(TestNode, 3) = .{};
    var first_high: TestNode = .{ .level = 0 };
    var promoted: TestNode = .{ .level = 1 };
    var trailing_middle: TestNode = .{ .level = 1 };

    try expect(queue.enqueue(&first_high));
    try expect(queue.enqueue(&promoted));
    try expect(queue.enqueue(&trailing_middle));
    try expect(queue.promote(&promoted));
    try expect(promoted.level == 0);
    try expect(queue.queues[1].head == &trailing_middle);

    try expect(queue.dequeue() == &first_high);
    try expect(queue.dequeue() == &promoted);
    try expect(queue.dequeue() == &trailing_middle);
}

test "demote relocates a queued task and preserves source FIFO order" {
    var queue: MultilevelQueue(TestNode, 3) = .{};
    var first_middle: TestNode = .{ .level = 1 };
    var demoted: TestNode = .{ .level = 1 };
    var first_low: TestNode = .{ .level = 2 };

    try expect(queue.enqueue(&first_middle));
    try expect(queue.enqueue(&demoted));
    try expect(queue.enqueue(&first_low));
    try expect(queue.demote(&demoted));
    try expect(demoted.level == 2);
    try expect(queue.queues[1].head == &first_middle);

    try expect(queue.dequeue() == &first_middle);
    try expect(queue.dequeue() == &first_low);
    try expect(queue.dequeue() == &demoted);
}

test "invalid, duplicate, absent, and boundary operations leave queues unchanged" {
    var queue: MultilevelQueue(TestNode, 3) = .{};
    var highest: TestNode = .{ .level = 0 };
    var lowest: TestNode = .{ .level = 2 };
    var absent: TestNode = .{ .level = 1 };
    var invalid: TestNode = .{ .level = 3 };

    try expect(queue.enqueue(&highest));
    try expect(queue.enqueue(&lowest));
    try expect(!queue.enqueue(&highest));
    try expect(!queue.add(&lowest));
    try expect(!queue.promote(&highest));
    try expect(!queue.demote(&lowest));
    try expect(!queue.promote(&absent));
    try expect(!queue.demote(&absent));
    try expect(!queue.enqueue(&invalid));
    try expect(!queue.promote(&invalid));
    try expect(!queue.demote(&invalid));

    try expect(queue.queues[0].len == 1);
    try expect(queue.queues[0].head == &highest);
    try expect(queue.queues[0].tail == &highest);
    try expect(queue.queues[2].len == 1);
    try expect(queue.queues[2].head == &lowest);
    try expect(queue.queues[2].tail == &lowest);
    try expect(highest.next == null);
    try expect(lowest.next == null);
}
