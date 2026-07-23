# 17 - Heap Allocator

I am not sure we 100% need/use a heap allocator, but I don't think it will hurt. It will also hopefully give a better understanding of Zig allocators.

At first glance I feel like we could define leftover space in the linker as a heap region, and then use a fixed buffer allocator in Zig.

The TCB currently holds each task's stack, so that memory is contained in the .bss section (the global task buffer is `undefined` to start). The MSP starts at the top of RAM and will grow down. If we are going to use a fixed size buffer for the heap, then we will need to decide a stack size for MSP before it runs into the heap. We used 1KB for tasks, and I think that sounds reasonable for MSP unless I am proven otherwise.

The heap is essnetially all of memory between the end of .bss and the top of RAM minus the MSP stack size. Here is some hand-typed ASCII art:

```txt
|------------|
|    MSP     |
|------------| <-- msp end
|            |
|            |
|   heap     |
|            |
|            |
|------------| <-- .bss end
|   .bss     |
|------------|
|   .data    |
|------------|
|   .text    |
|------------|
```

With a heap allocator, we could put the TCB's on the heap. This would allow us to allocate dynamically based on exactly how many tasks are registered, rather than having MAX_TASKS.

```zig
pub const MAX_TASKS = 8;
var tasks: [MAX_TASKS]task.TCB = undefined;
```

With MAX_TASKS, we are reserving more space than necessary if task count is less than MAX_TASKS, and with a 1KB task size that is valuable memory wasted.

## Post implementation

The changes were as follows:

- Define heap start and end addresses in the linker
- Create a `heap.zig` in the kernel module that creates a `std.heap.FixedBufferAllocator` using those memory addresses

