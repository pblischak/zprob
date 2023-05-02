//! Bernoulli distribution with parameter `p`.

const std = @import("std");
const Random = std.rand.Random;

/// Sampling function for a Bernoulli distribution.
///
/// Generate a random sample from a Bernoulli distribution with
/// probability of success `p`.
pub fn bernoulliSample(p: f64, rng: *Random) u8 {
    if (p <= 0.0 or 1.0 <= p) {
        @panic("Parameter `p` must be within the range 0 < p < 1.");
    }
    const random_val = rng.float(f64);
    if (p < random_val) {
        return 0.0;
    } else {
        return 1.0;
    }
}
