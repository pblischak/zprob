<div align="center">
<h1><tt>zprob</tt></h1>
<h3><i>
A Zig Library for Probability Distributions
</i></h3>
</div>

## A Fresh Start

To include `zprob` in a nice, fresh new Zig project, you can include it as
a git submodule within a dedicated subfolder in you main project folder (e.g.,
`libs/`). Below is a simple example for how you could start such a project:

```bash
# Make new project folder with libs/ folder inside
mkdir -p my_zig_proj/libs

# Change into new project folder and initialize it as a git repo
cd my_zig_proj/ && git init

# Initialize a new Zig command line application
zig init-exe

# Change into the libs folder and add zprob as a git submodule
cd libs/
git submodule add https://github.com/pblischak/zprob.git
```

To add `zprob` as a module to your new project, you'll only need to add two lines to
the default build script:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ** 1. Here we define the zprob module and the path to the main file
    const zprob_module = b.addModule(
        "zprob",
        .{ .source_file = .{ .path = "libs/zprob/src/zprob.zig" } }
    );

    const exe = b.addExecutable(.{
        .name = "zprob_demo",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // ** 2. Here we add the zprob module to our executable
    exe.addModule("zprob", zprob_module);

    exe.install();
    const run_cmd = exe.run();

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
```

## Acknowledgements

The `zprob` library is modeled after code from the following projects:

 - The [odin-lang rand libraries](https://github.com/odin-lang/Odin/tree/master/core/math/rand).
 - The [zig-gamedev](https://github.com/michal-z/zig-gamedev) Zig libraries.
 - The [rand_distr](https://github.com/rust-random/rand/tree/master/rand_distr) Rust library.
