const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
    });

    const boot2_elf = b.addExecutable(.{
        .name = "boot2",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });
    boot2_elf.root_module.addAssemblyFile(b.path("boot2.s"));
    boot2_elf.setLinkerScript(b.path("memmap_boot2.ld"));
    const boot2_bin = boot2_elf.addObjCopy(.{
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

    checksum.addFileArg(boot2_bin.getOutput());
    const checksummed_assembly = checksum.addOutputFileArg("boot2_patch.s");

    const checksummed_object = b.addObject(.{
        .name = "boot2_patch",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });
    checksummed_object.root_module.addAssemblyFile(checksummed_assembly);

    const install_checksummed_object = b.addInstallFile(
        checksummed_object.getEmittedBin(),
        "boot2_patch.o",
    );

    b.getInstallStep().dependOn(&install_checksummed_object.step);
}
