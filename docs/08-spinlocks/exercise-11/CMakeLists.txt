cmake_minimum_required(VERSION 3.13)

include(../../01-boot/exercise-1/blinky/pico_sdk_import.cmake)

project(race-condition C CXX ASM)

pico_sdk_init()

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/zig-out/main.o
    COMMAND zig build
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/*.zig
)

add_custom_target(
    zig_build ALL
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/zig-out/main.o
)

add_executable(race-condition)

add_dependencies(race-condition zig_build)

target_sources(race-condition PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/zig-out/main.o
)

target_link_libraries(race-condition pico_stdlib pico_multicore)

pico_enable_stdio_usb(race-condition 1)

pico_add_extra_outputs(race-condition)

