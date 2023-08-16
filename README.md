<div align="center">
<h1><tt>zprob</tt></h1>
<h3><i>
A Zig Module for Probability Distributions
</i></h3>
</div>


The `zprob` module implements functionality for working with probability distributions in Zig,
including generating random samples and calculating probabilities using mass/density functions.

<img src="https://github.com/pblischak/zprob/actions/workflows/ci.yml/badge.svg" alt="CI Status">

----

**Discrete Probability Distributions**

[Bernoulli](https://en.wikipedia.org/wiki/Bernoulli_distribution) ::
[Binomial](https://en.wikipedia.org/wiki/Binomial_distribution) ::
[Geometric](https://en.wikipedia.org/wiki/Geometric_distribution) ::
[Multinomial](https://en.wikipedia.org/wiki/Multinomial_distribution) ::
[Negative Binomial](https://en.wikipedia.org/wiki/Negative_binomial_distribution) ::
[Poisson](https://en.wikipedia.org/wiki/Poisson_distribution)

**Continuous Probability Distributions**

[Beta](https://en.wikipedia.org/wiki/Beta_distribution) ::
[Chi-squared](https://en.wikipedia.org/wiki/Chi-squared_distribution) ::
[Dirichlet](https://en.wikipedia.org/wiki/Dirichlet_distribution) ::
[Exponential](https://en.wikipedia.org/wiki/Exponential_distribution) ::
[Gamma](https://en.wikipedia.org/wiki/Gamma_distribution) ::
[Multivariate Normal](https://en.wikipedia.org/wiki/Multivariate_normal_distribution) (sampling only) ::
[Normal](https://en.wikipedia.org/wiki/Normal_distribution)

> **Note**
> `zprob` was developed and tested using v0.11.0 of Zig and is still a work in progress.
> Using a version of Zig other than 0.11.0 may lead to the code not compiling.

**TODO**:

 - [ ] [Multivariate Normal](https://en.wikipedia.org/wiki/Multivariate_normal_distribution) (PDF + log-PDF)
 - [ ] Integrate with new module system in Zig v0.11.0

## A Fresh Start

To use `zprob` in a nice, fresh new Zig project, you can include it as
a git submodule within a dedicated subfolder in you main project folder (e.g.,
`libs/`). Below is a simple example for how you could start such a project:

```bash
# Make new project folder with libs/ subfolder inside
mkdir -p my_zig_proj/libs

# Change into new project folder and initialize as a git repo
cd my_zig_proj/ && git init

# Initialize a new Zig command line application
zig init-exe

# Add zprob as a git submodule in the libs/ folder
git submodule add https://github.com/pblischak/zprob.git libs/zprob
```

To include `zprob` as a module to your new project, you'll only need to add two lines to
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

Now, inside the `src/main.zig` file in your project, you can import `zprob` like any other
module:

```zig
const zprob = @import("zprob");
```

## Examples

This repo contains a few simple examples of how to use the random sampling functionality
implemented in `zprob`. To build the examples, clone the repo and run
`zig build examples`:

```bash
git clone https://github.compblischak/zprob.git
cd zprob/
zig build examples
```

Each example file should compile into a binary executable with the same name in the `zig-out/bin`
folder.

### Pseudo-Random Number Generators

**Using the current time in microseconds**

- [How to use the random number generator in Zig]("https://zig.news/gowind/how-to-use-the-random-number-generator-in-zig-ef6")

```zig
const std = @import("std");

const seed = @intCast(u64, std.time.microTimestamp());
var prng = std.rand.Xoshiro256.init(seed);
const rand = prng.random();
```

**Using `/dev/urandom`**

- [Random Numbers on Zig Learn](https://ziglearn.org/chapter-2/#random-numbers)

```zig
const std = @import("std");

var prng = std.rand.Xoshiro256.init(blk: {
    var seed: u64 = undefined;
    try std.os.getrandom(std.mem.asBytes(&seed));
    break :blk seed;
});

const rand = prng.random();
```

## Acknowledgements

Code from the following repositories helped guide the development of `zprob`:

 - Some of the sampling algorithms are translated to Zig from
   [`ranlib.c`](https://people.sc.fsu.edu/~jburkardt/c_src/ranlib/ranlib.html).
 - The Odin-lang [rand libraries](https://github.com/odin-lang/Odin/tree/master/core/math/rand).
 - The [zig-gamedev](https://github.com/michal-z/zig-gamedev) Zig libraries.
 - The [rand_distr](https://github.com/rust-random/rand/tree/master/rand_distr) Rust library.
