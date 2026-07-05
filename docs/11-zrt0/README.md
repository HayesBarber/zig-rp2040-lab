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

---

Update is that I tried to build the MicroZig rp2040 [example](https://github.com/ZigEmbeddedGroup/microzig/tree/main/examples/raspberrypi/rp2xxx), but it was giving me more trouble than I think it is worth. 

I think the path forward is to use MicroZig as a reference, but opt for this project to be bare-metal with no dependencies (at least as much as reasonably possible).

## Update on what is next

At this point, I think we have come a long way and should start making progress towards the actual implementation of the scheduler.

Per the name of this chapter, we need to build out a zrt0 that branches into the application code. I think I can yank one of the existing second stage bootloaders that sets XIP for flash. Then I may opt to write zrt0 in zig similar to how MicroZig does it and define the vector table and whatnot there.

The plan will be to start creating the root-level file structure for the project instead of putting everything in exercise sub-directories (though I am still cool with doing that ad-hoc).

## Exercise 14: Build zrt0

Here is where this project's implementation really starts. We will be using what we have learned so far to build out boot2 (with checksum) and zrt0. We will pull what is re-usable from the pico-sdk and MicroZig.

```bash
arm-none-eabi-objdump -h zig-rp2040-lab
```

