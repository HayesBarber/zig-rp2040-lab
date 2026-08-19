# Zig RP2040 Lab

## Running the lab

Prerequisites:
- Zig version: 0.16.0
- [Picotool](https://github.com/raspberrypi/picotool) installed and on `$PATH`

```zsh
# Build the uf2 and load onto board (assuming board is connected and in bootsel mode)
zig build load
```

## Description

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


