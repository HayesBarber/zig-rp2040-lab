# 14 - Task Registration

What API will we expose for the programmer to register tasks with the scheduler? That is what we will answer in this chapter, as well as the task control block (TCB) structure.

A few things that come to mind around this subject:

- Static tasks or dynamic task creation?
- What should stack size be?
- Is a task assumped to be a loop? One iteration?
  - Expose multple APIs maybe?

I am thinking to start we will have tasks be comptime known. In `main.zig` the application code will need to have a `setup` function that will return a struct of all the tasks. The scheduler can then call the `setup` function to initialize the TCBs. Each TCB will have a name (for debugging), entrypoint, state (running, ready, etc.), time slice, stack pointer, and a buffer for the stack. My current understanding is that the task stacks need to be [8-byte aligned](https://developer.arm.com/documentation/ddi0403/d/System-Level-Architecture/System-Level-Programmers--Model/ARMv7-M-exception-model/Stack-alignment-on-exception-entry).

Context switching is not implemented yet, so this initial implemenation will just be a super loop of tasks. When we get to that point we will need to push an initial stack frame onto each task's stack and set its stack pointer accordinly.

