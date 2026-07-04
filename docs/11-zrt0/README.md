# 11 - zrt0

Now that we have gone over crt0, lets consider zrt0 (zig runtime 0). Presumably there doesn't need to be any difference, but the goal here is to start considering what things will look like if/when we get off the pico SDK.

## MicroZig

[MicroZig](https://github.com/ZigEmbeddedGroup/microzig) is a Zig SDK for embedded projects. When I first started this lab, MicroZig was on Zig 0.15, which was a contributing factor to me not using it as I was on Zig 0.16, but at the time of writing this MicroZig's main branch states a dev version of Zig 0.17.

MicroZig looks to be aiming to support a variety of chips, but per [their docs](https://microzig.tech/docs/getting-started/) the pico is the best supported.

As of right now I am not sure if I will swap over to MicroZig, but at the very least we can learn some things from their Zig implementation.

Lets see if we can find MicroZig's equivalent to crt0 for the rp2040. 

There is a `cortex_m.zig` file that contains a [startup logic struct](https://github.com/ZigEmbeddedGroup/microzig/blob/main/core/src/cpus/cortex_m.zig#L683-L683). This seems to be the rough equivalent, as I see some code for the vector table and reset handler.

The [MicroZig Internals](https://microzig.tech/docs/internals/) doc has some good info. It seems like linker scripts are generated.

I think a good next stup is to create a blinky program using MicroZig.

## Exercise 13: MicroZig Blinky

I am currently still on Zig 0.16, and 0.17 is still in dev. Lets see if anything breaks, and if so I can upgrade (yolo).

