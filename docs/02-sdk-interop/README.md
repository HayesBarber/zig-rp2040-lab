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

