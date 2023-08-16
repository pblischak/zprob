const std = @import("std");

// const files = [_][]const u8{
//     "zprob",
//     "bernoulli",
//     "beta",
//     "binomial",
//     "chi_squared",
//     "dirichlet",
//     "exponential",
//     "gamma",
//     "geometric",
//     "multinomial",
//     "multivariate_normal",
//     "negative_binomial",
//     "normal",
//     "poisson",
// };

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const zprob_module = b.addModule("zprob", .{ .source_file = .{ .path = "src/zprob.zig" } });

    const test_step = b.step("test", "Run zprob tests");
    const main_tests = b.addTest(.{
        // .root_source_file = .{ .path = "tests/test.zig" },
        .root_source_file = .{ .path = "src/zprob.zig" },
        .optimize = optimize,
        .target = target,
    });
    main_tests.addModule("zprob", zprob_module);

    const docs_step = b.step("docs", "Build zprob docs");
    const docs = b.addTest(.{
        .name = "zprob",
        .root_source_file = .{ .path = "src/zprob.zig" },
    });
    const install_docs = b.addInstallDirectory(.{
        .source_dir = docs.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    docs_step.dependOn(&install_docs.step);
    docs_step.dependOn(&docs.step);

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
        const install_example = b.addInstallArtifact(example, .{});
        example.addModule("zprob", zprob_module);
        example_step.dependOn(&example.step);
        example_step.dependOn(&install_example.step);
    }
}
