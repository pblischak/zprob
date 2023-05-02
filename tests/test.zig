const std = @import("std");
const zprob = @import("zprob");
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

test "Bernoulli" {
    const seed = 1234;
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var sum: f64 = 0.0;
    for (0..10000) |_| {
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

test "Binomial API" {
    const seed = 1234;
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var sum: f64 = 0.0;
    for (0..10000) |_| {
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
