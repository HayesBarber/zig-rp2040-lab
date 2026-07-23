# 17 - Heap Allocator

I am not sure we 100% need/use a heap allocator, but I don't think it will hurt. It will also hopefully give a better understanding of Zig allocators.

At first glance I feel like we could define leftover space in the linker as a heap region, and then use a fixed buffer allocator in Zig.

