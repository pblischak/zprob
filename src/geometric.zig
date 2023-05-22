//! Geometric distribution with parameter `p`.
//!
//! Records the number of failures before the first success.

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

const bernoulliSample = @import("bernoulli.zig").bernoulliSample;

pub fn geometricSample(comptime I: type, comptime F: type, p: F, rng: *Random) I {
    var n_trials: I = 0;
    var trial: I = bernoulliSample(p, rng);
    while (trial == 0) {
        trial = bernoulliSample(p, rng);
        n_trials += 1;
    }

    return n_trials;
}

pub fn geometricPmf(comptime I: type, comptime F: type, x: I, p: F) F {
    return @exp(geometricLnPmf(I, F, x, p));
}

pub fn geometricLnPmf(comptime I: type, comptime F: type, x: I, p: F) F {
    return @intToFloat(F, x) * @log(1.0 - p) + p;
}

test "Geometric API" {
    const seed = @intCast(usize, std.time.milliTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var sum: f64 = 0.0;
    const p: f64 = 0.1;
    for (0..10_000) |_| {
        const samp = geometricSample(u32, f64, p, &rng);
        sum += @intToFloat(f64, samp);
    }
    const avg: f64 = sum / 10_000.0;
    const mean: f64 = (1.0 - p) / p;
    const variance: f64 = (1.0 - p) / (p * p);
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        mean, avg, variance
    );
}
