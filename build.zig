const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const base_flags = [_][]const u8{
        "-std=c++17",
        "-Wall",
        "-Wextra",
        "-Wpedantic",
    };

    const flags = blk: {
        var f = std.BoundedArray([]const u8, 16).init(0) catch unreachable;
        f.appendSlice(&base_flags) catch unreachable;
        if (builtin.cpu.arch.isX86()) {
            f.appendSlice(&[_][]const u8{
                "-DSIMD",
                "-mavx2",
                "-mbmi2",
                "-msse2",
            }) catch unreachable;
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
            if (std.Target.arm.featureSetHas(builtin.cpu.features, .neon)) {
                f.appendSlice(&.{ "-DSIMD", "-DNEON" }) catch unreachable;
            }
            // rpi4 does not report neon feature, add it manually
            else if (std.mem.eql(u8, builtin.cpu.model.name, "cortex_a72")) {
                f.appendSlice(&.{ "-DSIMD", "-DNEON" }) catch unreachable;
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
    lib.addIncludePath(std.Build.LazyPath{ .path = "src/" });
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

    const test_exe = b.addExecutable(std.Build.ExecutableOptions{
        .name = "nnue-test",
    });
    test_exe.linkLibCpp();
    test_exe.addIncludePath(std.Build.LazyPath{ .path = "src/" });
    test_exe.addCSourceFiles(&[_][]const u8{
        "src/interface/chessint.cpp",
        "src/test/nnue_test.cpp",
    }, flags);
    b.installArtifact(test_exe);

    const test_cmd = b.addRunArtifact(test_exe);

    const test_step = b.step("test", "Run vendor test code");
    test_step.dependOn(&test_cmd.step);
}
