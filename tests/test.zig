const std = @import("std");
const zprob = @import("zprob");
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

const TestingState = struct {
    reps: usize,
    seed: u64,
    tolerance: f64,

    pub fn init(reps: ?usize, seed: ?u64, tol: ?f64) TestingState {
        return .{
            .reps = reps orelse 10_000,
            .seed = seed orelse @intCast(u64, std.time.microTimestamp()),
            .tolerance = tol orelse 0.1,
        };
    }
};

// Bernoulli Tests

test "Bernoulli" {
    const ts = TestingState.init(null, null, null);
    var prng = DefaultPrng.init(ts.seed);
    var rng = prng.random();
    var sum: f64 = 0.0;
    for (0..ts.reps) |_| {
        const samp = zprob.bernoulliSample(u8, f64, 0.4, &rng);
        sum += @intToFloat(f64, samp);
    }
    const avg: f64 = sum / 10000.0;
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        @as(f64, 0.4), avg, ts.tolerance
    );
    // zig fmt: on
}

test "Binomial" {
    const ts = TestingState.init(null, null, null);
    var prng = DefaultPrng.init(ts.seed);
    var rng = prng.random();
    var sum: f64 = 0.0;
    for (0..ts.reps) |_| {
        const samp = zprob.binomialSample(i32, f64, 10, 0.2, &rng);
        sum += @intToFloat(f64, samp);
    }
    const avg: f64 = sum / 10000.0;
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        @as(f64, 2.0), avg, ts.tolerance
    );
    // zig fmt: on
}

test "Exponential" {
    const ts = TestingState.init(null, null, null);
    var prng = DefaultPrng.init(ts.seed);
    var rng = prng.random();
    const lambda: f64 = 500.0;
    var sum: f64 = 0.0;
    var samp: f64 = undefined;
    for (0..ts.reps) |_| {
        samp = zprob.exponentialSample(f64, lambda, &rng);
        sum += samp;
    }
    const avg: f64 = sum / @intToFloat(f64, ts.reps);
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        1.0 / lambda, avg, ts.tolerance
    );
    // zig fmt: on
}

// Normal Distribution Tests

test "Normal Sample f64" {
    const ts = TestingState.init(null, null, null);
    var prng = DefaultPrng.init(ts.seed);
    var rng = prng.random();
    const mu: f64 = 5.0;
    const sigma = 2.0;
    var sum: f64 = 0.0;
    var samp: f64 = undefined;
    for (0..ts.reps) |_| {
        samp = zprob.normalSample(f64, mu, sigma, &rng);
        sum += samp;
    }
    const avg: f64 = sum / @intToFloat(f64, ts.reps);
    try std.testing.expectApproxEqAbs(mu, avg, ts.tolerance);
}
