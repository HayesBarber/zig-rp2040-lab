# 01 - Boot

The rp2040 has a [UF2](https://github.com/Microsoft/uf2) bootloader in ROM, which makes the device appear as a mass storage device (flash drive) to upload code to.

ROM is 16kB starting at address 0x00000000 and has fixed contents (startup routine, boot sequence, etc).

## Boot Sequence

Core 0 executes this. Core 1 goes to sleep until woken by user code.

If bootrom button is pressed (low), flash boot is skipped for USB mode bootcode.

For flash boot, loads 256 byte second stage from SPI into SRAM5 and checks checksum. If that passes, start executing the loaded code.

If nothing valid is found after 0.5 seconds, fallthrough to USB boot and appear as mass storage device.

## Second Stage: boot2

First 256 bytes of flash image.

## References

- https://vanhunteradams.com/Pico/Bootloader/Boot_sequence.html

