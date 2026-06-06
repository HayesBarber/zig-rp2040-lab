cmake_minimum_required(VERSION 3.13)

include(pico_sdk_import.cmake)

project(blinky C CXX ASM)

pico_sdk_init()

add_executable(blinky)

target_sources(blinky PRIVATE blinky.c)

# pico_cyw43_arch_none for pico W to use the LED: https://www.raspberrypi.com/documentation/pico-sdk/networking.html#:~:text=pico_cyw43_arch_none
target_link_libraries(blinky pico_stdlib pico_cyw43_arch_none)

# create map/bin/hex file etc.
pico_add_extra_outputs(blinky)

