# 01 - Boot

The rp2040 has a [UF2](https://github.com/Microsoft/uf2) bootloader in ROM, which makes the device appear as a mass storage device (flash drive) to upload code to.

ROM is 16kB starting at address 0x00000000 and has fixed contents (startup routine, boot sequence, etc).

## Boot Sequence

Core 0 executes this. Core 1 goes to sleep until woken by user code.

If bootrom button is pressed (low), flash boot is skipped for USB mode bootmode.

For flash boot, loads 256 byte second stage (boot2) from SPI into SRAM and checks checksum. If that passes, start executing the loaded code.

If nothing valid is found after 0.5 seconds, fallthrough to USB boot and appear as mass storage device.

Since the 1st stage boot is baked into the chip itself, it should be more or less impossible to brick a pico.

## Second Stage: boot2

First 256 bytes of flash image. This is what the 1st stage loads, checks, and branches to.

The second stage mostly sets up high speed comms for the flash chip, and then branches to the reset_handler.

Flash is not built into the RP2040, so it doesn't actually know what its talking to. The first stage basically tries a bunch of possible protocols and see if any work (checksum passes), and if not falls through to USB bootmode.

boot2 is _exactly_ 256 bytes, with the last 4 bytes being the checksum. It will pad with 0's if it is smaller.

## Reset Handler

As mentioned above, boot2 will branch to a reset_handler function.

Since RAM is volitile (doesn't persist through power cycles), this handler will load data/variables into RAM.

Upon completion, the reset_handler will branch to user application code.

## Linking

Linker scripts arrange object files (`.o`) to the memory layout of the target chip.

Specifies things like memory starting locations and sizes (Flash, RAM, etc).

It also maps sections from the object files (`.text`, `.data`, etc).

## Exercise 1: blinky

I looked at this [Serial_bootloader demo](https://github.com/vha3/Hunter-Adams-RP2040-Demos/tree/master/Bootloaders/Serial_bootloader) quite a bit. The idea of this demo is to create a custom 3rd stage bootloader that loads new app code over UART. There is also a modified linker script for building new app code that offsets the 3rd stage's memory range as to not overwrite it in flash. I am mainly using it as a reference to build a blinky program, along with [this blink.c example from rpi](https://github.com/raspberrypi/pico-examples/blob/master/blink/blink.c). These use C and CMake, but will be a good starting point for practice before getting into Zig.

### Setup

I think there is a VS-Code extension for Pico development, but I will using the command line (I use nvim btw). I am on a M1 Mac-Mini, and used [this document](https://vanhunteradams.com/Pico/Setup/PicoSetupMac.html) as a guide to installing the [Pico SDK](https://github.com/raspberrypi/pico-sdk).

I ran into a few issues when trying to build:

- The instructions mention `brew tap ArmMbed/homebrew-formulae` and `brew install arm-none-eabi-gcc`, but if you look at the [repo for this tap](https://github.com/armmbed/homebrew-formulae) it recommends `brew install --cask gcc-arm-embedded`
- The `CMakeLists.txt` references `include(pico_sdk_import.cmake)` which is part of the [pico-sdk](https://github.com/raspberrypi/pico-sdk/blob/master/external/pico_sdk_import.cmake). I have the SDK installed at `~/Pico/pico-sdk` and added `export PICO_SDK_PATH=~/Pico/pico-sdk` to my zshrc but it couldn't find this file. I opted to copy it directly into the directory and that seemed to work

### Building

The target is to build a `.uf2` to flash to the pico. This can be achieved by the following (from the root of the repo):

```bash
cd ./docs/01-boot/exercise-1/blinky
mkdir build
cd build
cmake -DPICO_BOARD=pico_w ..
make
```

If it worked, you should see `blinky.uf2` amongst other stuff:

```bash
ls

./
├── CMakeFiles/
├── generated/
├── pico-sdk/
├── pioasm/
├── pioasm-install/
├── blinky.bin*
├── blinky.dis
├── blinky.elf*
├── blinky.elf.map
├── blinky.hex
├── blinky.uf2   <-- this one
├── cmake_install.cmake
├── CMakeCache.txt
├── Makefile
└── pico_flash_region.ld
```

### Flashing

To flash the pico, hold down BOOTSEL and plug it into your computer. It should show up as a storage device. From there copy the `.uf2` and it will automatically reboot.

```bash
cp blinky.uf2 /Volumes/RPI-RP2
```

# ___Important Update___

I decided to stop by Micro Center and pick up a normal pico (not a W). The wifi module introduces some complexity that is unnessary for this project. The primary example being controlling the onboard LED, which on the W requires going through the wifi module as compared to a simple GPIO update.

## Exercise 2: blinky with no SDK

The next exercise will be building blinky again, but this time with minimal SDK involvement. It's not that I don't plan on using the SDK with Zig, but after some research it appears to be quite involved to flush out all the includes that will allow you to `zig build` and use the pic-sdk with FFI. Now that I am more comfortable with the boot sequence and linking, this felt like a good next step. This will still use C, but hopefully after this step there will be a ~direct Zig equivalent.

This exercise will be using this [RPi Pico Baremetal project](https://github.com/carlosftm/RPi-Pico-Baremetal). In particular the [02_Flash_2_SRAM_SDK](https://github.com/carlosftm/RPi-Pico-Baremetal/tree/main/02_Flash_2_SRAM_SDK) example.

If you look into that directory, you will see the following:

- `boot2.s`
  - Assembly for a custom second stage bootloader
  - Initializes flash, copies app code from flash to RAM, and branches to it
  - No `reset_hanlder` that I can see (I don't think it is necessary for this program)
- `memmap_boot2.ld`
  - Linker script for `boot2.s`
- `blink_flash.c`
  - The blinky C program
  - Uses raw memory address to toggle LED
  - The `main()` function signiture is kinda funky. It defines `section( ".boot.entry" )` that is later utilized by the linker. This will essentially allow for us to put the function at a specified known location in memory and branch to it (which can be seen at the bottom of `_copyToRam` in the `boot2.s` assembly)
- `memmap.ld`
  - Linker script for `blink_flash.c`
  - Lays out `boot2` and `boot.entry` in memory right next to each other
  - Asserts that `boot2` is 256 bytes, which is required by the rp2040
- `Makefile`
  - Builds and links
  - Builds the `.uf2` using picotool
  - Only uses the pico-sdk to `pad_checksum` for `boot2`

You can build this example as follows (note that you may need to adjust the `PICOSDK` and `PICOTOOL` paths in the `Makefile`):

```bash
git clone https://github.com/carlosftm/RPi-Pico-Baremetal.git
cd RPi-Pico-Baremetal/02_Flash_2_SRAM_SDK
make # adjust paths as needed for PICOSDK and PICOTOOL
```

This will build the `.uf2`, and is flashed to the pico via the same process mentioned earlier.

### Branch Confusion

I was confused why `boot2` was branching to `0x20000101` and not `0x20000100`:

```asm
ldr r0, =0x20000101
bx  r0
```

If `boot2` is exactly 256 bytes in in RAM, wouldn't that mean it occupies the range `0x20000000` - `0x200000FF`? Which would make the beginning of main `0x20000100`?

From what I understand this _is the case_, and the trailing `1` in `0x20000001` is a bit set to signal Thumb state. The `ARM Cortex-M0+` processor (which the rp2040 uses) executes the Thumb instruction set.

### Where is the Reset Handler?

My understanding is that, due to the simplicity of the program, there is no need for one. In the pico-sdk's [exit_from_boot2.S](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2040/boot_stage2/asminclude/boot2_helpers/exit_from_boot2.S) it sets up the main stack pointer (MSP), and vectors to the reset handler. This is nicely explained in Hunter Adam's [RP2040 Boot Sequence](https://vanhunteradams.com/Pico/Bootloader/Boot_sequence.html#Exit-from-boot-stage-2) docs. But for this program there is essentially no variables, and it more-or-less cannot crash. As such, there is no reset handler or vector table.

## Exercise 3: _Zig_ blinky

The goal will be to utilize the same second stage bootloader and linkers from exercise 2, but replace `blink_flash.c` with `blinky.zig` and `Makefile` with `build.zig`.

## Exercise ???: Zig with pico-sdk

I think my approach will be to interop with pico-sdk via Zig FFI.

I found a repo, ["zig-pico-sdk"](https://github.com/gwagner/zig-pico-sdk), which seems like a good starting point

## References

The lectures from V. Hunter Adams (Cornell) were incredibly valuable in learning this stuff.

In particular, the [RP2040 Boot Sequence](https://www.youtube.com/watch?v=MegBMmtmgHA) and [Custom Serial Bootloader](https://www.youtube.com/watch?v=j9aQkl5gTZI&t=2919s). Videos are also [documented on this website](https://vanhunteradams.com/Pico/Bootloader/Boot_sequence.html), and there is an associated [GitHub Repo](https://github.com/vha3/Hunter-Adams-RP2040-Demos).

