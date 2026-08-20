# Zig RP2040 Lab

## Running the lab

Prerequisites:
- Zig version: 0.16.0
- [Picotool](https://github.com/raspberrypi/picotool) installed and on `$PATH`

```zsh
# Build the uf2 and load onto board (assuming board is connected and in bootsel mode)
zig build load
```

The application code is a UART console. To listen to the serial port I use [picocom](https://github.com/npat-efault/picocom): `picocom -b 115200 /dev/cu.usbserial-0001`

I also use a UART-to-USB adapter wired up to GND, GPIO-0 for RX, and GPIO-1 for TX.

Type 'help' to explore the CLI.

## Description

The goal for this project was to build a bare metal CPU scheduler for the RP2040 in Zig.

The `docs/` directory contains the chronological order of topics I covered in order to build it. As you can see, there were a lot of topics to cover before I even got to the first context switch.

This project was a lot of fun, and provided a sense of clarity to some topics that often get abstracted away.

## Project Structure

```txt
./
├── docs/          ->  Cumulative journal
├── src/
│   ├── boot/      ->  Second stage bootloader
│   ├── core/      ->  HAL
│   ├── kernal/    ->  Scheduler and kernel APIs
│   └── main.zig   ->  Application code
└── build.zig      ->  Builds the uf2
```

## References

I provide links to references throughout the `docs/`, but these feel especially important:

- [RP2040 Datasheet](https://pip-assets.raspberrypi.com/categories/814-rp2040/documents/RP-008371-DS-1-rp2040-datasheet.pdf)
- [Pico SDK](https://github.com/raspberrypi/pico-sdk)
- [MicroZig](https://github.com/ZigEmbeddedGroup/microzig)
- [V. Hunter Adams](https://vanhunteradams.com/)
- [RPi-Pico-Baremetal](https://github.com/carlosftm/RPi-Pico-Baremetal)
- [Pico Examples](https://github.com/raspberrypi/pico-examples)
- [Life with David](https://github.com/LifeWithDavid/RaspberryPiPico-BareMetalAdventures)

