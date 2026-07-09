const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize: std.builtin.OptimizeMode = .ReleaseSmall;
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
    });

    const boot2_bin = build_boot2(b, target, optimize);

    const boot2_mod = b.createModule(.{ .root_source_file = boot2_bin });
    const bootrom_mod = b.createModule(.{
        .root_source_file = b.path("src/boot/stage2/rp2040_bootrom.zig"),
    });
    bootrom_mod.addImport("bootloader", boot2_mod);
    const zrt0_mod = b.createModule(.{
        .root_source_file = b.path("src/boot/zrt0/zrt0.zig"),
    });
    zrt0_mod.addImport("bootrom", bootrom_mod);

    const core_mod = b.createModule(.{
        .root_source_file = b.path("src/core/mod.zig"),
    });

    const fw = b.addExecutable(.{
        .name = "zig-rp2040-lab",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    fw.root_module.addImport("zrt0", zrt0_mod);
    fw.root_module.addImport("core", core_mod);
    fw.setLinkerScript(b.path("src/boot/zrt0/rp2040.ld"));
    b.installArtifact(fw);
    const fw_bin = fw.addObjCopy(.{
        .format = .bin,
    });
    const install_bin = b.addInstallBinFile(fw_bin.getOutput(), "zig-rp2040-lab.bin");
    b.getInstallStep().dependOn(&install_bin.step);

    const uf2 = b.addSystemCommand(&.{
        "picotool",
        "uf2",
        "convert",
    });
    uf2.addFileArg(fw_bin.getOutput());
    const uf2_file = uf2.addOutputFileArg("zig-rp2040-lab.uf2");
    uf2.addArg("-o");
    uf2.addArg("0x10000000");
    uf2.addArg("--family");
    uf2.addArg("rp2040");
    const install_uf2 = b.addInstallFile(
        uf2_file,
        "zig-rp2040-lab.uf2",
    );
    b.getInstallStep().dependOn(&install_uf2.step);
}

fn build_boot2(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) std.Build.LazyPath {
    const boot2_exe = b.addExecutable(.{
        .name = "boot2-w25q080",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    boot2_exe.setLinkerScript(b.path("src/boot/stage2/shared/stage2.ld"));
    boot2_exe.root_module.addAssemblyFile(b.path("src/boot/stage2/w25q080.S"));
    boot2_exe.entry = .{ .symbol_name = "_stage2_boot" };

    const boot2_objcopy = b.addObjCopy(boot2_exe.getEmittedBin(), .{
        .basename = "w25q080.bin",
        .format = .bin,
    });

    return boot2_objcopy.getOutput();
}
