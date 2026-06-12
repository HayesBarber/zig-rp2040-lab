# 02 - Pico SDK Interoperability

I think there two plausible approaches

1. Entirely use the zig build system and include all the needed files from the SDK
2. Use the SDKs `cmake` buildsystem and have it link in a zig built `.o` file

I think the latter would be easier. The `CMakeLists.txt` file could just call `zig build`.

## Exercise 4: Zig blinky using the pico sdk

I went with approach 2. 

The `CMakeLists.txt` initializes the pico sdk, calls `zig build`, and then links everything together. The `build.zig` simply outputs an object file.

The benefit of this is that I can use the sdk's bootloader and reset handler.

In `blinky.zig`, I use `sleep_ms` from the sdk by stubbing it as `extern`. This is probably not the best dev experience, and I got build errors when trying to call functions like [gpio_put](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/hardware_gpio/include/hardware/gpio.h#L1155-L1155) which are `static inline`. For this project it should be fine. The main thing I wanted was to use the bootloader and reset handler.

To make a build and flash (working directory should be exercise-4):

```bash
mkdir build
cd build
cmake ..
make
cp blinky.uf2 /Volumes/RPI-RP2
```

## Exercise 5: Print messages over USB

I would also like to be able to print to the console of my dev machine while the pico is connected via USB. To my understanding the pico sdk has a `printf` implementation, so I will start there.

---

That turned out to be correct. `main.zig` defines printf as an `extern` function and that can be used to print over USB. 

The output can be seen via:

```bash
cat /dev/cu.usbmodem12201
```

I did need to add `pico_enable_stdio_usb(hello-world 1)` to the `CMakeLists.txt` in order to see the device in `/dev/`

