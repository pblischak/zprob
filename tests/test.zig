const std = @import("std");
const zprob = @import("zprob");
const DefaultPrng = std.rand.Xoshiro256;

var test_allocator = std.testing.allocator;

const TestingState = struct {
    reps: usize,
    seed: u64,
    tolerance: f64,
    denom: f64,

    pub fn init(reps: ?usize, seed: ?u64, tol: ?f64) TestingState {
        var denom: f64 = undefined;
        if (reps) |val| {
            denom = @as(f64, @floatFromInt(val));
        } else {
            denom = 10_000.0;
        }
        return .{
            .reps = reps orelse 10_000,
            .seed = seed orelse @intCast(std.time.microTimestamp()),
            .tolerance = tol orelse 0.1,
            .denom = denom,
        };
    }
};

test "Bernoulli" {
    const ts = TestingState.init(null, null, null);
    var prng = DefaultPrng.init(ts.seed);
    var rng = prng.random();
    var bernoulli = zprob.Bernoulli(u8, f64).init(&rng);
    var sum: f64 = 0.0;
    var samp: u8 = undefined;
    for (0..ts.reps) |_| {
        samp = bernoulli.sample(0.4);
        sum += @as(f64, @floatFromInt(samp));
    }
    const avg: f64 = sum / ts.denom;
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
    var binomial = zprob.Binomial(i32, f64).init(&rng);
    var sum: f64 = 0.0;
    var samp: i32 = undefined;
    for (0..ts.reps) |_| {
        samp = binomial.sample(10, 0.2);
        sum += @as(f64, @floatFromInt(samp));
    }
    const avg: f64 = sum / ts.denom;
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        @as(f64, 2.0), avg, ts.tolerance
    );
    // zig fmt: on
}

test "Geometric" {
    const ts = TestingState.init(null, null, null);
    var prng = DefaultPrng.init(ts.seed);
    var rng = prng.random();
    var geometric = zprob.Geometric(i32, f64).init(&rng);
    var sum: f64 = 0.0;
    const p: f64 = 0.2;
    var samp: i32 = undefined;
    for (0..ts.reps) |_| {
        samp = geometric.sample(p);
        sum += @as(f64, @floatFromInt(samp));
    }
    const avg: f64 = sum / ts.denom;
    const mean: f64 = (1.0 - p) / p;
    const variance: f64 = (1.0 - p) / (p * p);
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        mean, avg, variance
    );
}

test "Multinomial" {
    const ts = TestingState.init(null, null, null);
    var prng = DefaultPrng.init(ts.seed);
    var rng = prng.random();
    var multinomial = zprob.Multinomial(i32, f64).init(&rng);
    var p_vec = [3]f64{ 0.1, 0.25, 0.65 };
    var out_vec = [3]i32{ 0, 0, 0 };
    var sum_vec = [3]i32{ 0, 0, 0 };
    // zig fmt: off
    var mean_vec = [3]f64{ 1.0, 2.5, 6.5 };
    var variance_vec = [3]f64{
        10.0 * 0.1 * 0.9,
        10.0 * 0.25 * 0.75,
        10.0 * 0.65 * 0.35,
    };
    for (0..ts.reps) |_| {
        multinomial.sample(10, 3, p_vec[0..], out_vec[0..]);
        sum_vec[0] += out_vec[0];
        sum_vec[1] += out_vec[1];
        sum_vec[2] += out_vec[2];
    }
    const avg_vec = [3]f64{
        @as(f64, @floatFromInt(sum_vec[0])) / ts.denom,
        @as(f64, @floatFromInt(sum_vec[1])) / ts.denom,
        @as(f64, @floatFromInt(sum_vec[2])) / ts.denom,
    };
    // zig fmt: on
    try std.testing.expectApproxEqAbs(mean_vec[0], avg_vec[0], variance_vec[0]);
    try std.testing.expectApproxEqAbs(mean_vec[1], avg_vec[1], variance_vec[1]);
    try std.testing.expectApproxEqAbs(mean_vec[2], avg_vec[2], variance_vec[2]);
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
    const avg: f64 = sum / ts.denom;
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        1.0 / lambda, avg, ts.tolerance
    );
    // zig fmt: on
}

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
    const avg: f64 = sum / ts.denom;
    try std.testing.expectApproxEqAbs(mu, avg, ts.tolerance);
}
