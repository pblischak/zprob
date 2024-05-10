const std = @import("std");

pub fn build(b: *std.Build) void {
    const root_source_file = b.path("src/zprob.zig");

    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    _ = b.addModule(
        "zprob",
        .{ .root_source_file = root_source_file },
    );

    const main_tests = b.addTest(.{
        .root_source_file = root_source_file,
        .optimize = optimize,
        .target = target,
    });
    const run_main_tests = b.addRunArtifact(main_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_main_tests.step);
}
