//! Normal distribution with parameters `mu` (mean) and `sigma` (standard deviation).

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;

pub fn Normal(comptime F: type) type {
    return struct {
        const Self = @This();

        prng: *Random,

        pub fn init(prng: *Random) Self {
            return Self{
                .prng = prng,
            };
        }

        pub fn sample(self: Self, mu: F, sigma: F) F {
            const value = self.prng.floatNorm(F);
            return value * sigma + mu;
        }

        pub fn pdf(mu: F, sigma: F, x: F) F {
            // zig fmt: off
            return 1.0 / (sigma * @sqrt(2.0 * math.pi))
                * @exp(-(1.0 / 2.0) * math.pow(F, (x - mu) / sigma, 2));
            // zig fmt: on
        }

        pub fn normalLnPdf(x: F, mu: F, sigma: F) F {
            return -@log(sigma * @sqrt(2.0 * math.pi)) + math.pow(F, (x - mu) / sigma, 2);
        }
    };
}
