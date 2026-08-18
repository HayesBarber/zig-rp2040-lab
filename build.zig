const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize: std.builtin.OptimizeMode = .ReleaseSmall;
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
    });

    const core_mod = b.createModule(.{
        .root_source_file = b.path("src/core/mod.zig"),
    });

    const kernal_mod = b.createModule(.{
        .root_source_file = b.path("src/kernal/mod.zig"),
    });
    kernal_mod.addImport("core", core_mod);

    const test_step = b.step("test", "Run unit tests");
    addDiscoveredTests(b, test_step, core_mod, kernal_mod);

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
    zrt0_mod.addImport("core", core_mod);
    zrt0_mod.addImport("kernal", kernal_mod);

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
    fw.root_module.addImport("kernal", kernal_mod);
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

    const load_step = b.step("load", "Load firmware to Pico via picotool");
    const load_cmd = b.addSystemCommand(&.{ "picotool", "load", "-uxf" });
    load_cmd.addFileArg(uf2_file);
    load_step.dependOn(&load_cmd.step);
}

fn addDiscoveredTests(
    b: *std.Build,
    test_step: *std.Build.Step,
    core_mod: *std.Build.Module,
    kernal_mod: *std.Build.Module,
) void {
    const io = b.graph.io;
    var source_dir = b.build_root.handle.openDir(io, "src", .{ .iterate = true }) catch @panic("unable to open source directory");
    defer source_dir.close(io);

    var walker = source_dir.walk(b.allocator) catch @panic("out of memory");
    var test_index: usize = 0;
    while (walker.next(io) catch @panic("unable to walk source directory")) |entry| {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.path, ".zig")) continue;

        var source_file = entry.dir.openFile(io, entry.basename, .{}) catch @panic("unable to open source file");
        const stat = source_file.stat(io) catch @panic("unable to stat source file");
        const source = b.allocator.alloc(u8, @intCast(stat.size)) catch @panic("out of memory");
        const bytes_read = source_file.readPositionalAll(io, source, 0) catch @panic("unable to read source file");
        source_file.close(io);

        if (!containsTestDeclaration(source[0..bytes_read])) continue;

        const test_root = b.createModule(.{
            .root_source_file = b.path(b.pathJoin(&.{ "src", entry.path })),
            .target = b.graph.host,
            .optimize = .Debug,
        });
        test_root.addImport("core", core_mod);
        test_root.addImport("kernal", kernal_mod);

        const tests = b.addTest(.{
            .name = b.fmt("test-{d}", .{test_index}),
            .root_module = test_root,
        });
        test_index += 1;
        const run_tests = b.addRunArtifact(tests);
        test_step.dependOn(&run_tests.step);
    }
}

fn containsTestDeclaration(source: []const u8) bool {
    var start: usize = 0;
    while (std.mem.indexOfPos(u8, source, start, "test")) |index| {
        const before_is_identifier = index != 0 and isIdentifierCharacter(source[index - 1]);
        const after_index = index + "test".len;
        const after_is_whitespace = after_index < source.len and std.ascii.isWhitespace(source[after_index]);
        if (!before_is_identifier and after_is_whitespace) return true;
        start = after_index;
    }
    return false;
}

fn isIdentifierCharacter(char: u8) bool {
    return std.ascii.isAlphanumeric(char) or char == '_';
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
