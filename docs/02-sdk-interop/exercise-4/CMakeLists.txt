cmake_minimum_required(VERSION 3.13)

include(../../01-boot/exercise-1/blinky/pico_sdk_import.cmake)

project(blinky C CXX ASM)

pico_sdk_init()

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/zig-out/blinky.o
    COMMAND zig build
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/build.zig
        ${CMAKE_CURRENT_SOURCE_DIR}/blinky.zig
)

add_custom_target(
    zig_build ALL
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/zig-out/blinky.o
)

add_executable(blinky)

add_dependencies(blinky zig_build)

target_sources(blinky PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/zig-out/blinky.o
)

target_link_libraries(blinky pico_stdlib)

pico_add_extra_outputs(blinky)

