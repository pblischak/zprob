//! Normal distribution with parameters `mu` (mean) and `sigma` (standard deviation).

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

pub fn normalSample(comptime T: type, mu: T, sigma: T, rng: *Random) T {
    const value = rng.floatNorm(T);
    return value * sigma + mu;
}

pub fn normalPdf(comptime T: type, mu: T, sigma: T, x: T) T {
    // zig fmt: off
    return 1.0 / (sigma * @sqrt(2.0 * math.pi))
        * @exp(-(1.0 / 2.0) * math.pow(T, (x - mu) / sigma, 2));
    // zig fmt: on
}

pub fn normalLnPdf(comptime T: type, mu: T, sigma: T, x: T) T {
    return -@log(sigma * @sqrt(2.0 * math.pi)) + math.pow(T, (x - mu) / sigma, 2);
}
