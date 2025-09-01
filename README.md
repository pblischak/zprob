<div align="center">
<h1><tt>zprob</tt></h1>
<h3><i>
A Zig Module for Random Number Distributions
</i></h3>
</div>

The `zprob` module implements functionality for working with probability distributions in pure Zig,
including generating random samples and calculating probabilities using mass/density functions.
The instructions below will get you started with integrating `zprob` into your project, as well as
introducing some basic use cases. For more detailed information on the different APIs that `zprob`
implements, please refer to the [docs site](https://github.com/pblischak/zprob).

## Getting Started

### `RandomEnvironment` API

Below we show a small example program that introduces the `RandomEnvironment` struct, which
provides a high-level interface for sampling from distributions and calculating probabilities. It
automatically generates and stores everything needed to begin generating random numbers
(seed + random generator), and follows the standard Zig convention of initialization with an
`Allocator` that handles memory allocation.

```zig
const std = @import("std");
const zprob = @import("zprob");

pub fn main() !void {
    // Set up main memory allocator and defer deinitilization
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const status = gpa.deinit();
        std.testing.expect(status == .ok) catch {
            @panic("Memory leak!");
        };
    }

    // Set up random environment and defer deinitialization
    var env = try zprob.RandomEnvironment.init(allocator);
    defer env.deinit();

    // Generate random samples
    const binomial_sample = try env.rBinomial(10, 0.8);
    const geometric_sample = try env.rGeometric(0.3);
    std.debug.print("b = {};\tg = {}\n", .{ binomial_sample, geometric_sample });

    // Generate slices of random samples. The caller is responsible for cleaning up
    // the allocated memory for the slice.
    const binomial_slice = try env.rBinomialSlice(100, 20, 0.4);
    defer allocator.free(binomial_slice);
}
```

To initialize a `RandomEnvironment` with a particular seed, use the `initWithSeed` method:

```zig
var env = try zprob.RandomEnvironment.initWithSeed(1234567890, allocator);
defer env.deinit();
```

### Distributions API

While the easiest way to get started using `zprob` is with the `RandomEnvironment` struct,
for users wanting more fine-grained control over the construction and usage of different probability
distributions, `zprob` provides a lower level "Distributions API".

```zig
const std = @import("std");
const zprob = @import("zprob");

pub fn main() !void {
    // Set up random generator.
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    // Same as: `const beta = zprob.Beta(f64){}`;
    const beta = zprob.default_beta;
    // Same as: `const binomial = zprob.Binomial(u32, f64){}`
    const binomial = zprob.default_binomial;

    var b1: f64 = undefined;
    var b2: u32 = undefined;
    for (0..100) |_| {
        b1 = try beta.sample(1.0, 5.0, &rand);
        b2 = try binomial.sample(20, b1, &rand);
    }
}
```

## Example Projects

As mentioned briefly above, there are several projects in the
[examples/](https://github.com/pblischak/zprob/tree/main/examples) folder that demonstrate the
usage of `zprob` for different applications:

- **approximate_bayes:** Uses approximate Bayesian computation to estimate the posterior mean
  and standard deviation of a normal distribution using a small sample of observations.
- **compound_distributions:** Illustrates how to generate samples from compound probability
  distributions such as the Beta-Binomial.
- **distribution_sampling:** Shows the basics of the "Distributions API" through the construction
  of distribution structs with different underlying types.
- **enemy_spawner:** Shows a gamedev motivated use case where distinct enemy types are sampled
  with different frequencies, are given different stats based on their type, and are placed randomly
  on the level map.

## Available Distributions

**Discrete Probability Distributions**

[Bernoulli](https://en.wikipedia.org/wiki/Bernoulli_distribution) ::
[Binomial](https://en.wikipedia.org/wiki/Binomial_distribution) ::
[Geometric](https://en.wikipedia.org/wiki/Geometric_distribution) ::
[Multinomial](https://en.wikipedia.org/wiki/Multinomial_distribution) ::
[Negative Binomial](https://en.wikipedia.org/wiki/Negative_binomial_distribution) ::
[Poisson](https://en.wikipedia.org/wiki/Poisson_distribution) ::
[Uniform](https://en.wikipedia.org/wiki/Discrete_uniform_distribution)

**Continuous Probability Distributions**

[Beta](https://en.wikipedia.org/wiki/Beta_distribution) ::
[Cauchy](https://en.wikipedia.org/wiki/Cauchy_distribution) ::
[Chi-squared](https://en.wikipedia.org/wiki/Chi-squared_distribution) ::
[Dirichlet](https://en.wikipedia.org/wiki/Dirichlet_distribution) ::
[Exponential](https://en.wikipedia.org/wiki/Exponential_distribution) ::
[Gamma](https://en.wikipedia.org/wiki/Gamma_distribution) ::
[Normal](https://en.wikipedia.org/wiki/Normal_distribution) ::
[Uniform](https://en.wikipedia.org/wiki/Continuous_uniform_distribution)

## Installation

To include `zprob` in your Zig project, you can add it to your `build.zig.zon` file
using the `zig fetch` command.

The `main` branch tracks the latest release of Zig (currently v0.14.0) and can be added
as follows:

```
zig fetch --save git+https://github.com/pblischak/zprob/
```

The `nightly` branch tracks the Zig `master` branch and can be added by adding `#nightly` to the
git URL:

```
zig fetch --save git+https://github.com/pblischak/zprob/#nightly
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

Check out the build files in the [examples/](https://github.com/pblischak/zprob/tree/main/examples)
folder for some demos of complete sample code projects.

## Issues

If you run into any problems while using `zprob`, please consider filing an issue describing the
problem, as well as any steps that may be required to reproduce the problem.

## Contributing

We are open for contributions! Please see our contributing guide for more information on how you
can help build new features for `zprob`.

## Other Useful Links

- [https://ziglang.org/documentation/master/std/#std.Random](https://ziglang.org/documentation/master/std/#std.Random)
- [https://zig.guide/standard-library/random-numbers](https://zig.guide/standard-library/random-numbers)
- [https://github.com/statrs-dev/statrs](https://github.com/statrs-dev/statrs)
- [https://github.com/rust-random/rand_distr](https://github.com/rust-random/rand_distr)
