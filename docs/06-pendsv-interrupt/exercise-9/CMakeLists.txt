cmake_minimum_required(VERSION 3.13)

include(../../01-boot/exercise-1/blinky/pico_sdk_import.cmake)

project(pending-supervisor-call C CXX ASM)

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

add_executable(pending-supervisor-call)

add_dependencies(pending-supervisor-call zig_build)

target_sources(pending-supervisor-call PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/zig-out/main.o
)

target_link_libraries(pending-supervisor-call pico_stdlib)

pico_enable_stdio_usb(pending-supervisor-call 1)

pico_add_extra_outputs(pending-supervisor-call)

