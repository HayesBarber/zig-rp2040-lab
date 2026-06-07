const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize: std.builtin.OptimizeMode = .ReleaseSmall;
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
        .name = "boot2_patch_o",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });
    checksummed_object.root_module.addAssemblyFile(checksummed_assembly);

    const blinky_object = b.addObject(.{
        .name = "blinky_o",
        .root_module = b.createModule(.{
            .root_source_file = b.path("blinky.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    blinky_object.link_gc_sections = true;
    blinky_object.root_module.single_threaded = true;

    const blinky_elf = b.addExecutable(.{
        .name = "blinky",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });
    blinky_elf.root_module.addObject(checksummed_object);
    blinky_elf.root_module.addObject(blinky_object);
    blinky_elf.setLinkerScript(b.path("memmap.ld"));
    const blinky_bin = boot2_elf.addObjCopy(.{
        .format = .bin,
    });

    const uf2 = b.addSystemCommand(&.{
        "picotool",
        "uf2",
        "convert",
    });
    uf2.addFileArg(blinky_bin.getOutput());
    const uf2_file = uf2.addOutputFileArg("blinky.uf2");
    uf2.addArg("-o");
    uf2.addArg("0x10000000");
    uf2.addArg("--family");
    uf2.addArg("rp2040");

    const install_uf2 = b.addInstallFile(
        uf2_file,
        "blinky.uf2",
    );
    b.getInstallStep().dependOn(&install_uf2.step);
}
