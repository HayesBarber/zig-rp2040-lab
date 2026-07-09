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

---

Alrighty, we now have a root-level file structure that I am happy with, and a zrt0 the invokes the main application code. The directory structure I am thinking of rocking with is this:

```txt
.
├── src/
│   ├── boot/
│   │   ├── stage2/
│   │   └── zrt0/
│   ├── core/
│   ├── kernal/
│   └── main.zig
└── build.zig
```

The scheduler code will reside in `kernal`, and embedded/pico code will live in `core`. The `stage2` directory houses the second stage bootloader that was yanked from the pico-sdk and MicroZig. `zrt0.zig` holds the vector table, as well as the function to copy over `.data` and `.bss`. There is also a `rp2040.ld` linker script that lays out all the memory locations.

I also want to break down `build.zig` as it is crifical:

1. Build boot2 into a `.bin` 
  - Uses `w25q080.S` from RPI/MicroZig
  - Configures XIP
2. Adds `w25q080.bin` as a module for `rp2040_bootrom.zig` with name `bootloader`
  - This allows `rp2040_bootrom.zig` to `@embedFile` and compute the CRC, and then `export linksection(".boot2")`
3. Adds the checksummed boot2 as an import to `zrt0`
  - `zrt0` does a comptime reference to it so that it doesn't get excluded
4. The main `zig-rp2040-lab` executable is built with `zrt0` added as a module
  - `main.zig` similarly does a comptime reference to `zrt0`
5. Use `picotool` to convert to `uf2`

The pico-sdk and MicroZig were critical in getting this all to work, so all credit to those projects.

