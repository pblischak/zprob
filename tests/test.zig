const std = @import("std");
const zprob = @import("zprob");
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

const TEST_REPS: usize = 10_000;
const TEST_SEED: u64 = @as(u64, std.time.microTimestamp());

test "Bernoulli" {
    var prng = DefaultPrng.init(TEST_SEED);
    var rng = prng.random();
    var sum: f64 = 0.0;
    for (0..TEST_REPS) |_| {
        const samp = zprob.bernoulliSample(0.4, &rng);
        sum += @intToFloat(f64, samp);
    }
    const avg: f64 = sum / 10000.0;
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        @as(f64, 0.4), avg, 0.1
    );
    // zig fmt: on
}

test "Binomial" {
    var prng = DefaultPrng.init(TEST_SEED);
    var rng = prng.random();
    var sum: f64 = 0.0;
    for (0..TEST_REPS) |_| {
        const samp = zprob.binomialSample(10, 0.2, &rng);
        sum += @intToFloat(f64, samp);
    }
    const avg: f64 = sum / 10000.0;
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        @as(f64, 2.0), avg, 0.1
    );
    // zig fmt: on
}

test "Exponential" {
    var prng = DefaultPrng.init(TEST_SEED);
    var rng = prng.random();
    const lambda: f64 = 500.0;
    var sum: f64 = 0.0;
    for (0..TEST_REPS) |_| {
        const samp = zprob.exponentialSample(lambda, &rng);
        sum += samp;
    }
    const avg: f64 = sum / 10000.0;
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        1.0 / lambda, avg, 0.1
    );
    // zig fmt: on
}
