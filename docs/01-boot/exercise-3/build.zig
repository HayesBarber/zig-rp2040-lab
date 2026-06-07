const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
    });

    const exe = b.addExecutable(.{
        .name = "boot2",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addAssemblyFile(b.path("boot2.s"));
    exe.setLinkerScript(b.path("memmap_boot2.ld"));

    const bin = exe.addObjCopy(.{
        .format = .bin,
    });

    // todo bring this internal
    const checksum = b.addSystemCommand(&.{
        "pad_checksum",
        "-p",
        "256",
        "-s",
        "0xFFFFFFFF",
    });

    checksum.addFileArg(bin.getOutput());
    const patch_s = checksum.addOutputFileArg("boot2_patch.s");

    const boot2_patch = b.addObject(.{
        .name = "boot2_patch",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });
    boot2_patch.root_module.addAssemblyFile(patch_s);

    const install_patch = b.addInstallFile(
        boot2_patch.getEmittedBin(),
        "boot2_patch.o",
    );

    b.getInstallStep().dependOn(&install_patch.step);
}
