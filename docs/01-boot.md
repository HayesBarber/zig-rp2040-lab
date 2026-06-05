# 01 - Boot

The rp2040 has a [UF2](https://github.com/Microsoft/uf2) bootloader in ROM, which makes the device appear as a mass storage device (flash drive) to upload code to

ROM is 16kB starting at address 0x00000000 and has fixed contents (startup routine, boot sequence, etc.)

