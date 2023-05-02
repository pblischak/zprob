const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const zprob_module = b.addModule("zprob", .{ .source_file = .{ .path = "src/zprob.zig" } });

    const test_step = b.step("test", "Run zprob tests");
    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "tests/test.zig" },
        .optimize = optimize,
        .target = target,
    });
    main_tests.addModule("zprob", zprob_module);

    const run_tests = b.addRunArtifact(main_tests);
    test_step.dependOn(&run_tests.step);

    const example_step = b.step("examples", "Build examples");
    for ([_][]const u8{"binomial_sampling"}) |example_file| {
        const example = b.addExecutable(.{
            .name = example_file,
            .root_source_file = .{ .path = b.fmt("examples/{s}.zig", .{example_file}) },
            .target = target,
            .optimize = optimize,
        });
        const install_example = b.addInstallArtifact(example);
        example.addModule("zprob", zprob_module);
        example_step.dependOn(&example.step);
        example_step.dependOn(&install_example.step);
    }
}
