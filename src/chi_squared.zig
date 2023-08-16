//! Chi-squared distribution with degrees of freedom `k`.

// zig fmt: off

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;

const Gamma = @import("gamma.zig").Gamma;
const spec_fn = @import("special_functions.zig");

pub fn ChiSquared(comptime I: type, comptime F: type) type {
    return struct{
        const Self = @This();

        prng: *Random,
        gamma: Gamma(F),

        pub fn init(prng: *Random) Self {
            return Self{
                .prng = prng,
                .gamma = Gamma(F).init(prng),
            };
        }

        pub fn sample(self: Self, k: I) F {
            const b: F = @as(F, @floatFromInt(k)) / 2.0;
            const k_usize: usize = @intCast(k);

            var x2: F = undefined;
            var x: F = undefined;
            if (k <= 100) {
                x2 = 0.0;
                for (0..k_usize) |_| {
                    x = self.prng.floatNorm(F);
                    x2 += x * x;
                }
            } else {
                x2 = self.gamma.sample(b, 0.5);
            }

            return x2;
        }

        pub fn pdf(self: Self, x: F, k: I) F {
            if (x < 0.0) {
                return 0.0;
            }

            return @exp(self.lnPdf(k, x));
        }

        pub fn lnPdf(x: F, k: I) F {
            var b: F = @as(F, @floatFromInt(k)) / 2.0;
            return -(b * @log(2.0) + spec_fn.lnGammaFn(F, b)) - b + (b - 1.0) * @log(x);
        }
    };
}

test "Chi-squared API" {
    const DefaultPrng = std.rand.Xoshiro256;
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var chi_squared = ChiSquared(i32, f64).init(&rng);
    var sum: f64 = 0.0;
    for (0..10_000) |_| {
        sum += chi_squared.sample(10);
    }
    const avg = sum / 10_000.0;
    std.debug.print("{}\n", .{avg});
}
