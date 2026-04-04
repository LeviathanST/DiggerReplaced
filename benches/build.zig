const std = @import("std");

pub fn build(b: *std.Build) void {
    const t = b.standardTargetOptions(.{});
    const o = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = t,
        .optimize = o,
    });

    const zbench = b.dependency("zbench", .{
        .target = t,
        .optimize = o,
    }).module("zbench");

    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const ecs_mod = b.addModule("ecs", .{
        .root_source_file = b.path("../src/ecs.zig"),
        .target = t,
        .optimize = o,
        .imports = &.{
            .{ .name = "raylib", .module = raylib },
        },
    });

    const ecs_modules = &[_][]const u8{ "query", "stress_query" };
    inline for (ecs_modules) |m| {
        const exe = b.addExecutable(.{
            .name = "bench_ecs_" ++ m,
            .root_module = b.createModule(.{
                .root_source_file = b.path("ecs/" ++ m ++ ".zig"),
                .target = t,
                .optimize = o,
            }),
        });
        exe.root_module.addImport("ecs", ecs_mod);
        b.installArtifact(exe);

        exe.linkLibrary(raylib_artifact);
        exe.root_module.addImport("raylib", raylib);
        exe.root_module.addImport("zbench", zbench);

        if (b.findProgram(&.{"poop"}, &.{}) catch null) |poop_path| {
            const run_poop_cmd = b.addSystemCommand(&.{
                poop_path,
                "zig-out/bin/bench_" ++ "ecs_" ++ m,
            });
            run_poop_cmd.step.dependOn(b.getInstallStep());

            const run_step = b.step("bench-ecs-" ++ m, "Run the ecs benchmarks");
            run_step.dependOn(&run_poop_cmd.step);
        }
    }
}
