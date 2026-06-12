cmake_minimum_required(VERSION 3.13)

include(../../01-boot/exercise-1/blinky/pico_sdk_import.cmake)

project(hello-world C CXX ASM)

pico_sdk_init()

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/zig-out/main.o
    COMMAND zig build
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/build.zig
        ${CMAKE_CURRENT_SOURCE_DIR}/main.zig
)

add_custom_target(
    zig_build ALL
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/zig-out/main.o
)

add_executable(hello-world)

add_dependencies(hello-world zig_build)

target_sources(hello-world PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/zig-out/main.o
)

target_link_libraries(hello-world pico_stdlib)

pico_enable_stdio_usb(hello-world 1)

pico_add_extra_outputs(hello-world)

