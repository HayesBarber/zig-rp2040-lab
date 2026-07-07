MEMORY
{
    FLASH(rx) : ORIGIN = 0x10000000, LENGTH = 2048k
    RAM(rwx)  : ORIGIN = 0x20000000, LENGTH = 256k
}

__stack_top = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
    .text : {
      __boot2_start__ = .;
      KEEP(*(.boot2))
      __boot2_end__ = .;
      KEEP(*(.vectors))
      KEEP(*(.text*))
    } > FLASH
            
    ASSERT(__boot2_end__ - __boot2_start__ == 256,
        "ERROR: Pico second stage bootloader must be 256 bytes in size")

    .data : {
      *(.data*)
    } > RAM AT> FLASH

    .bss (NOLOAD) : {
      *(.bss*)
    } > RAM
}
