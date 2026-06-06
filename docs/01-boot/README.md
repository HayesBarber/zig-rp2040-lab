# 01 - Boot

The rp2040 has a [UF2](https://github.com/Microsoft/uf2) bootloader in ROM, which makes the device appear as a mass storage device (flash drive) to upload code to.

ROM is 16kB starting at address 0x00000000 and has fixed contents (startup routine, boot sequence, etc).

## Boot Sequence

Core 0 executes this. Core 1 goes to sleep until woken by user code.

If bootrom button is pressed (low), flash boot is skipped for USB mode bootmode.

For flash boot, loads 256 byte second stage (boot2) from SPI into SRAM5 and checks checksum. If that passes, start executing the loaded code.

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

## Exercise 1: Get a boot2 blinky built

I am going to basing off this [Serial_bootloader demo](https://github.com/vha3/Hunter-Adams-RP2040-Demos/tree/master/Bootloaders/Serial_bootloader). It uses C and CMake, but will be a good starting point to put the above into practice before getting into Zig. The idea of this demo is to create a custom 3rd stage bootloader that loads new app code over UART. There is also a modified linker script for building new app code that offsets the 3rd stage's memory range as to not overwrite it in flash. I am mainly using it as a starting point to build a blinky program, and won't be using and 3rd stage stuff.

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
cmake ..
make
```

If it worked, you should see `blinky.uf2` amongst other stuff:

```bash
tree -L 1

./
├── _deps/
├── CMakeFiles/
├── generated/
├── pico-sdk/
├── picotool/
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

## References

The lectures from V. Hunter Adams (Cornell) were incredibly valuable in learning this stuff.

In particular, the [RP2040 Boot Sequence](https://www.youtube.com/watch?v=MegBMmtmgHA) and [Custom Serial Bootloader](https://www.youtube.com/watch?v=j9aQkl5gTZI&t=2919s). Videos are also [documented on this website](https://vanhunteradams.com/Pico/Bootloader/Boot_sequence.html), and there is an associated [GitHub Repo](https://github.com/vha3/Hunter-Adams-RP2040-Demos).

