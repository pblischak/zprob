//! Negative binomial distribution with parameters `p`, `n`, and `r`.

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;

const Gamma = @import("gamma.zig").Gamma;
const Poisson = @import("poisson.zig").Poisson;
const spec_fn = @import("special_functions.zig");

pub fn NegativeBinomial(comptime I: type, comptime F: type) type {
    return struct {
        const Self = @This();

        prng: *Random,
        poisson: Poisson(I, F),
        gamma: Gamma(F),

        pub fn init(prng: *Random) Self {
            return Self{
                .prng = prng,
                .poisson = Poisson(I, F).init(prng),
                .gamma = Gamma(F).init(prng),
            };
        }

        pub fn sample(self: Self, n: I, p: F) I {
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

            r = @as(F, @floatFromInt(n));
            a = (1.0 - p) / p;
            y = self.gamma.sample(a, r);
            value = self.poisson.sample(y);

            return value;
        }

        pub fn pmf(self: Self, k: I, r: I, p: F) F {
            return @exp(self.lnPmf(k, r, p));
        }

        pub fn lnPmf(k: I, r: I, p: F) F {
            const k_f = @as(F, @floatFromInt(k));
            const r_f = @as(F, @floatFromInt(r));
            return spec_fn.lnNChooseK(I, F, k + r - 1, k) + k_f * @log(1.0 - p) + r_f * @log(p);
        }
    };
}

test "Negative Binomial API" {
    const DefaultPrng = std.rand.Xoshiro256;
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var neg_binomial = NegativeBinomial(i32, f64).init(&rng);
    var sum: i32 = 0.0;
    for (0..10_000) |_| {
        sum += neg_binomial.sample(10, 0.9);
    }
    const avg = @as(f64, @floatFromInt(sum)) / 10_000.0;
    std.debug.print("{}\n", .{avg});
}
