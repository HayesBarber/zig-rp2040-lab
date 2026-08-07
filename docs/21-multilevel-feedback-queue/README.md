# 21 - Multilevel Feedback Queue

The next scheduling algorithm I would like to implement is the multilevel feedback queue. This will attempt to classify task's behavior into I/O bound and CPU bound. Tasks that block/yeild get "promoted", while tasks that use their entire time slice get "demoted".

When a task gets promoted/demoted, it moves into different ready queues. These queues are then prioritized come scheduling time, with I/O being the higher priority.

One could implement this with 3 queues: one for I/O, one for CPU, and one in the middle. All task's start in the middle queue, and move around based on their observed behavior.

Why stop at 3 queues, we could have N queues and have it be a gradient situation. This would allow for some tasks to be "more" I/O bound than others. I would imagine there is eventually some diminishing returns with too many queues, and trying to search them all for a ready task.

Note that, depending on how this is implemented, there is the potential for task starvation. One way around this is to introduce an "aging" concept that will promote tasks to higher priority queues based on how long it has been ready.

One could also implement different algorithms for each queue.

For this project, I am thinking of implementing the following spec:

- N queues
  - All tasks start in the 0 + (N/2) queue
  - 0..N is I/0..CPU
- Each queue is a FIFO for scheduling
- Tasks that block get promoted (move closer to queue 0)
- Tasks that use entire time slice get demoted (move closer to queue N-1)

## References

- https://www.cs.uic.edu/~jbell/CourseNotes/OperatingSystems/6_CPU_Scheduling.html

