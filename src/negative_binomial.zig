//! Negative binomial distribution with parameters `p`, `n`, and `r`.

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

const gammaSample = @import("gamma.zig").gammaSample;
const poissonSample = @import("poisson.zig").poissonSample;
const lnNChooseK = @import("special_functions.zig").lnNChooseK;

pub fn negBinomialSample(comptime I: type, comptime F: type, n: I, p: F, rng: *Random) I {
    var a: F = undefined;
    var r: F = undefined;
    var y: F = undefined;
    var value: I = undefined;

    if (n <= 0) {
        @panic("Number of trials cannot be negative...");
    }

    if (p <= 0.0) {
        @panic("Probability of success cannot be less than or equal to 0...");
    }

    if (1.0 <= p) {
        @panic("Probability of success cannot be greater than or equal to 1...");
    }

    r = @as(F, n);
    a = (1.0 - p) / p;
    y = gammaSample(F, a, r, rng);
    value = poissonSample(I, F, y, rng);

    return value;
}

pub fn negBinomialPmf(comptime I: type, comptime F: type, k: I, r: I, p: F) F {
    return @exp(negBinomialLnPmf(I, F, k, r, p));
}

pub fn negBinomialLnPmf(comptime I: type, comptime F: type, k: I, r: I, p: F) F {
    const k_f = @as(F, k);
    const r_f = @as(F, r);
    return lnNChooseK(I, F, k + r - 1, k) + k_f * @log(1.0 - p) + r_f * @log(p);
}

test "Negative Binomial API" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var sum: i32 = 0.0;
    for (0..10_000) |_| {
        sum += negBinomialSample(i32, f64, 10, 0.9, &rng);
    }
    const avg = @as(f64, sum) / 10_000.0;
    std.debug.print("{}\n", .{avg});
}
