const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize: std.builtin.OptimizeMode = .ReleaseSmall;
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
    });

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("c.h"),
        .target = target,
        .optimize = optimize,
    });
    translate_c.addIncludePath(b.path("pico-sdk/src/boards/include/boards"));
    translate_c.addIncludePath(b.path("pico-sdk/src/common/pico_time/include"));
    translate_c.addIncludePath(b.path("pico-sdk/src/host/hardware_timer/include"));
    translate_c.addIncludePath(b.path("pico-sdk/src/host/hardware_sync/include"));
    translate_c.addIncludePath(b.path("pico-sdk/src/common/pico_sync/include"));

    const main_object = b.addObject(.{
        .name = "main_o",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "c",
                    .module = translate_c.createModule(),
                },
            },
        }),
    });
    const install_object = b.addInstallFile(main_object.getEmittedBin(), "main.o");
    b.getInstallStep().dependOn(&install_object.step);
}
