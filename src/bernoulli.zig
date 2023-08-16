//! Bernoulli distribution with parameter `p`.

const std = @import("std");
const Random = std.rand.Random;

pub fn Bernoulli(comptime I: type, comptime F: type) type {
    return struct {
        const Self = @This();

        prng: *Random,

        pub fn init(prng: *Random) Self {
            return Self{
                .prng = prng,
            };
        }

        /// Sampling function for a Bernoulli distribution.
        ///
        /// Generate a random sample from a Bernoulli distribution with
        /// probability of success `p`.
        pub fn sample(self: Self, p: F) I {
            if (p <= 0.0 or 1.0 <= p) {
                @panic("Parameter `p` must be within the range 0 < p < 1.");
            }
            const random_val = self.prng.float(F);
            if (p < random_val) {
                return 0;
            } else {
                return 1;
            }
        }
    };
}

test "Bernoulli struct API" {
    var seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.rand.Xoroshiro128.init(seed);
    var rng = prng.random();
    const bernoulli = Bernoulli(u8, f64).init(&rng);
    const val = bernoulli.sample(0.4);
    std.debug.print("\n{}\n", .{val});
}
