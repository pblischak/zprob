//! Bernoulli distribution with parameter `p`.

const std = @import("std");
const Random = std.rand.Random;

/// Sampling function for a Bernoulli distribution.
///
/// Generate a random sample from a Bernoulli distribution with
/// probability of success `p`.
pub fn bernoulliSample(comptime I: type, comptime F: type, p: F, rng: *Random) I {
    if (p <= 0.0 or 1.0 <= p) {
        @panic("Parameter `p` must be within the range 0 <= p <= 1.");
    }
    const random_val = rng.float(F);
    if (p < random_val) {
        return 0;
    } else {
        return 1;
    }
}
