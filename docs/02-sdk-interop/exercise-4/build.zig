const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize: std.builtin.OptimizeMode = .ReleaseSmall;
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
    });

    const blinky_object = b.addObject(.{
        .name = "blinky_o",
        .root_module = b.createModule(.{
            .root_source_file = b.path("blinky.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const install_object = b.addInstallFile(blinky_object.getEmittedBin(), "blinky.o");
    b.getInstallStep().dependOn(&install_object.step);
}
