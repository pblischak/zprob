<div align="center">
<h1><tt>zprob</tt></h1>
<h3><i>
A Zig Module for Probability Distributions
</i></h3>
<img src="https://github.com/pblischak/zprob/actions/workflows/ci.yml/badge.svg" alt="CI Status"> [![docs](https://github.com/pblischak/zprob/actions/workflows/pages/pages-build-deployment/badge.svg)](https://pblischak.github.io/zprob/)
</div>

The `zprob` module implements functionality for working with probability distributions in pure Zig,
including generating random samples and calculating probabilities using mass/density functions.
The instructions below will get you started with integrating `zprob` into your project, as well as
introducing some basic use cases. For more detailed information on the different APIs that `zprob`
offers, please refer to the [docs site](https://github.com/pblischak/zprob).

## Installation

> **Note:**
> The current version of `zprob` was developed and tested using v0.12.0 of Zig and is still a work in progress.
> Using a version of Zig other than 0.12.0 may lead to the code not compiling.

To include `zprob` in your Zig project, you can add it to your `build.zig.zon` file in the
dependencies section:

```zon
.{
    .name = "my_project",
    .version = "0.1.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "README.md",
        "LICENSE",
        "src",
    },
    .dependencies = .{
        // This will link to tagged v0.2.0 release.
        // Change the url and hash to link to a specific commit.
        .zprob = {
            .url = "",
            .hash = "",
        }
    },
}
```

Then, in the `build.zig` file, add the following lines within the `build` function to include
`zprob` as a module:

```zig
pub fn build(b: *std.Build) void {
    // exe setup...

    const zprob_dep = b.dependency("zprob", .{
            .target = target,
            .optimize = optimize,
    });

    const zprob_module = zprob_dep.module("zprob");
    exe.root_module.addImport("zprob", zprob_module);

    // additional build steps...
}
```

Check out the [examples/](https://github.com/pblischak/zprob/tree/main/examples) folder for
complete sample code projects.

## Getting Started

Below we show a brief "Hello, World!" program for using `zprob`. 

```zig
const std = @import("std");
const zprob = @import("zprob");

pub fn main() !void {
    // Set up main memory allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const status = gpa.deinit();
        std.testing.expect(status == .ok) catch {
            @panic("Memory leak!");
        };
    }

    // Set up random environment
    var env = try zprob.RandomEnvironment.init(allocator);

    // Generate random samples
    const binomial_sample = env.rBinomial(10, 0.8);


    // Generate slices of random samples. The caller is responsible for cleaning up
    // the allocated memory for the slice.
    const binomial_slice = try env.rBinomialSlice(100, 20, 0.4);
    defer allocator.free(binomial_samples);
}
```

## Example Projects



## Low-Level Distributions API





## Available Distributions

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
[Normal](https://en.wikipedia.org/wiki/Normal_distribution)


## Other Useful Links

- [https://zig.guide/standard-library/random-numbers](https://zig.guide/standard-library/random-numbers)
