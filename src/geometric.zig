//! Geometric distribution with parameter `p`.
//!
//! Records the number of failures before the first success.

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

const bernoulliSample = @import("bernoulli.zig").bernoulliSample;

pub fn geometricSample(comptime I: type, comptime F: type, p: F, rng: *Random) I {
    const u: F = rng.float(F);
    return @as(I, @log(u) / @log(1.0 - p)) + 1;
}

pub fn geometricPmf(comptime I: type, comptime F: type, k: I, p: F) F {
    return @exp(geometricLnPmf(I, F, k, p));
}

pub fn geometricLnPmf(comptime I: type, comptime F: type, k: I, p: F) F {
    return @as(F, k) * @log(1.0 - p) + @log(p);
}

test "Geometric API" {
    const seed: u64 = @intCast(std.time.milliTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var sum: f64 = 0.0;
    const p: f64 = 0.01;
    for (0..10_000) |_| {
        const samp = geometricSample(u32, f64, p, &rng);
        sum += @as(f64, samp);
    }
    const avg: f64 = sum / 10_000.0;
    const mean: f64 = (1.0 - p) / p;
    const variance: f64 = (1.0 - p) / (p * p);
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        mean, avg, variance
    );
}
