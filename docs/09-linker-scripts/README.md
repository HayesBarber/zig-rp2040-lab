# 09 - Linker Scripts

Although this project has interacted with linker scripts in some previous chapters, I realized I didn't really do a deep dive on them. I wouldn't say that I feel comfortable with the syntax before this chapter, so lets see what we can learn. I could imagine a scenario where this project uses a custom linker for task stacks/heaps/etc.

## What is in a linker script?

I would say there are two primary things in a linker script: memory layout and sections. Variables can also be created that can be referenced in code.

### Memory Layout

The `MEMORY` block specifies memory addresses (start address) and lengths. Take this example from [the pico bare-metal repo](https://github.com/carlosftm/RPi-Pico-Baremetal/blob/main/02_Flash_2_SRAM_SDK/memmap.ld):

```ld
MEMORY
{
    FLASH(rx) : ORIGIN = 0x10000000, LENGTH = 2048k
    RAM(rwx)  : ORIGIN = 0x20000000, LENGTH = 256k
}
```

This defines flash memory to start at `0x10000000`, have a length 2048k bytes, and is read/executable (rx). Similar gist for RAM, but RAM is defined as read/write/executable (rwx). The read/write/executable attributes are descriptions rather than setting a policy.

### Sections

Sections arrange data within the memory blocks. For example, where does our application code go? Initialized global variables? Un-initialized variables? Convention is the following:

- `.text`: code
- `.data`: initialized variables
- `.bss`: un-initialized variables (to be zero-ed out)

Taking a loot at the sections from the same bare-metal linker:

```ld
SECTIONS
{
    .text : {
        . = ORIGIN(RAM);
        __boot2_start__ = .;
        KEEP(*(.boot2))
        __boot2_end__ = .;
        KEEP(*(.boot.entry))
        KEEP(*(.text*))
        __end_code_ = .;
    } > RAM
            
    ASSERT(__boot2_end__ - __boot2_start__ == 256,
        "ERROR: Pico second stage bootloader must be 256 bytes in size")
}
```

There is only a `.text` section for this simple example. Lets break is down:

- The `. = ORIGIN(RAM)` line sets the location counter to the start of RAM
  - The location counter increments as sections are added, and can be set like this for alignment and whatnot
- The next 3 lines reserve space for the second stage bootloader
- It then lays out the boot entry and remainder of text
  - Notice that the `.boot.entry` aligns with the section label used in the [main function](https://github.com/carlosftm/RPi-Pico-Baremetal/blob/main/02_Flash_2_SRAM_SDK/blink_flash.c#L7)
- The `> RAM` at the end of the section specifies that this section is in the RAM memory region

Some other things I think are noteworthy:

- Notice that there is another linker script in the [bare-metal example](https://github.com/carlosftm/RPi-Pico-Baremetal/blob/main/02_Flash_2_SRAM_SDK/memmap_boot2.ld) specifically for boot2 which puts it in flash instead. Based on what we know about the boot sequence this makes sense, since the RP2040 will load the first 256 bytes from flash into RAM. Since boot2 is it's own standalone program, it has it's own linker script.
- Linkers sections have two addresses: load address (LMA) and virtual address (VMA). LMA is kinda like initial storage location (e.g. flash), while VMA is where it runs. You can specify this mapping in the linker via `AT`. For example: `> RAM AT > FLASH` would say the section is run in RAM but stored in flash. If `AT` is omitted, LMA = VMA.
- We can also see some variables being set to memory locations. In this case there is an assertion that boot2 is 256 bytes.

## References

- https://interrupt.memfault.com/blog/how-to-write-linker-scripts-for-firmware
- https://dev.to/ripan030/linker-scripts-explained-controlling-memory-layout-on-bare-metal-3ocb

