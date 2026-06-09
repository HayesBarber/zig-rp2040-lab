# 02 - Pico SDK Interoperability

I think there two plausible approaches

1. Entirely use the zig build system and include all the needed files from the SDK
2. Use the SDKs `cmake` buildsystem and have it link in a zig built `.o` file

I think the latter would be easier. The `CMakeLists.txt` file could just call `zig build`.

## Exercise 4: Zig blinky using the pico sdk

