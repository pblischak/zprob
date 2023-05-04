//! Exponential distribution with parameter `lambda`.

const std = @import("std");
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

pub fn exponentialSample(lambda: f64, rng: *Random) f64 {
    return -@log(1.0 - rng.float(f64)) / lambda;
}

pub fn exponentialPdf(lambda: f64, x: f64) f64 {
    if (x < 0) {
        return 0.0;
    }
    return lambda * @exp(-lambda * x);
}

pub fn exponentialLnPdf(lambda: f64, x: f64) f64 {
    if (x < 0) {
        @panic("Cannot evaluate x less than 0.");
    }
    return -lambda * x * @log(lambda) + 1.0;
}
