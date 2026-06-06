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
    const install_bin = b.addInstallBinFile(bin.getOutput(), "boot2.bin");
    b.getInstallStep().dependOn(&install_bin.step);
}
