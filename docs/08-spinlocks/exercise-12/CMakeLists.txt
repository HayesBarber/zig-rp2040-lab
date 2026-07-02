cmake_minimum_required(VERSION 3.13)

include(../../01-boot/exercise-1/blinky/pico_sdk_import.cmake)

project(no-more-race C CXX ASM)

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

add_executable(no-more-race)

add_dependencies(no-more-race zig_build)

target_sources(no-more-race PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/zig-out/main.o
)

target_link_libraries(no-more-race pico_stdlib pico_multicore)

pico_enable_stdio_usb(no-more-race 1)

pico_add_extra_outputs(no-more-race)

