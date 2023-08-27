const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const nnue = b.option(bool, "nnue", "Enable NNUE") orelse false;
    // const options = b.addOptions();
    // options.addOption(bool, "nnue", nnue);

    const base_flags = [_][]const u8{ "-Wall", "-DSIMD" };

    const flags = blk: {
        var f = std.BoundedArray([]const u8, 16).init(0) catch unreachable;
        f.appendSlice(&base_flags) catch unreachable;
        if (builtin.cpu.arch.isX86()) {
            // if (std.Target.x86.featureSetHas(builtin.cpu.features, .avx512)) {
            //     f.append("-DAVX512") catch unreachable;
            // }
            if (std.Target.x86.featureSetHas(builtin.cpu.features, .avx2)) {
                f.append("-DAVX2") catch unreachable;
            }
            // if (std.Target.x86.featureSetHas(builtin.cpu.features, .sse)) {
            //     f.append("-DUSE_SSE -msse") catch unreachable;
            // }
            // if (std.Target.x86.featureSetHas(builtin.cpu.features, .sse2)) {
            //     f.append("-DUSE_SSE2 -msse2") catch unreachable;
            // }
            // if (std.Target.x86.featureSetHas(builtin.cpu.features, .sse3)) {
            //     f.append("-DUSE_sse3 -msse3") catch unreachable;
            // }
            // if (std.Target.x86.featureSetHas(builtin.cpu.features, .sse4_1)) {
            //     f.append("-DUSE_SSE41 -msse4.1") catch unreachable;
            // }
        } else if (builtin.cpu.arch.isAARCH64()) {
            // rpi4 does not report neon feature :-(
            f.append("-DUSE_NEON") catch unreachable;
            if (std.Target.arm.featureSetHas(builtin.cpu.features, .neon)) {
                f.append("-DUSE_NEON") catch unreachable;
            }
        }

        break :blk f.constSlice();
    };

    const lib = b.addStaticLibrary(std.Build.StaticLibraryOptions{
        .name = "jdart_nnue",
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibCpp();
    lib.addIncludePath(std.Build.LazyPath{
        .path = "src/",
    });
    lib.addCSourceFiles(&[_][]const u8{"src/interface/chessint.cpp"}, flags);

    // exe.addOptions("build_options", options);

    b.installArtifact(lib);

    // const run_cmd = b.addRunArtifact(exe);
    // run_cmd.step.dependOn(b.getInstallStep());
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);
}
