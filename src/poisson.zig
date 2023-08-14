//! Poisson distribution with parameter `lambda`.

// zig fmt: off

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;

const spec_fn = @import("special_functions.zig");

pub fn Poisson(comptime I: type, comptime F: type) type {
    return struct {
        const Self = @This();

        prng: *Random,

        pub fn init(prng: *Random) Self {
            return Self{
                .prng = prng,
            };
        }

        pub fn sample(self: Self, lambda: F) I {
            if (lambda < 17.0) {
                if (lambda < 1.0e-6) {
                    if (lambda == 0.0) {
                        return 0;
                    }

                    if (lambda < 0.0) {
                        @panic("Parameter lambda cannot be negative...");
                    }

                    return self.low(lambda);
                } else {
                    return self.inversion(lambda);
                }
            } else {
                if (lambda > 2.0e9) {
                    @panic("Parameter lambda too large...");
                }
                return self.ratioUniforms(lambda);
            }
        }

        fn low(self: Self, lambda: F) I {
            const d: F = @sqrt(lambda);
            if (self.prng.float(F) >= d) {
                return 0;
            }

            const r = self.prng.float(F) * d;
            if (r > lambda * (1.0 - lambda)) {
                return 0;
            }
            if (r > 0.5 * lambda * lambda * (1.0 - lambda)) {
                return 1;
            }

            return 2;
        }

        fn inversion(self: Self, lambda: F) I {
            const bound: I = 130;
            const p_f0 = @exp(-lambda);
            var x: I = undefined;
            var r: F = undefined;
            var f: F = p_f0;

            while (true) {
                r = self.prng.float(F);
                x = 0;
                f = p_f0;

                // Run first iteration since there is no do-while
                r -= f;
                if (r <= 0.0) {
                    return x;
                }
                x += 1;
                f += lambda;
                f += @as(F, @floatFromInt(x));

                while (x <= bound) {
                    r -= f;
                    if (r <= 0.0) {
                        return x;
                    }
                    x += 1;
                    f += lambda;
                    f += @as(F, @floatFromInt(x));
                }
            }
        }

        fn ratioUniforms(self: Self, lambda: F) I {
            var u: F = undefined;
            var lf: F = undefined;
            var x: F = undefined;
            var k: I = undefined;

            var p_a = lambda + 0.5;
            var mode = @as(I, @intFromFloat(lambda));
            var p_g = @log(lambda);
            var p_q = @as(F, @floatFromInt(mode)) * p_g - spec_fn.lnFactorial(I, F, mode);
            var p_h = @sqrt(2.943035529371538573 * (lambda + 0.5)) + 0.8989161620588987408;
            var p_bound = @as(I, @intFromFloat(p_a + 6.0 * p_h));

            while (true) {
                u = self.prng.float(F);
                if (u == 0) {
                    continue;
                }

                x = p_a + p_h * (self.prng.float(F) - 0.5) / u;
                if (x < 0.0 or x >= @as(F, @floatFromInt(p_bound))) {
                    continue;
                }

                k = @as(I, @intFromFloat(x));
                lf = @as(F, @floatFromInt(k)) * p_g - spec_fn.lnFactorial(I, F, k) - p_q;
                if (lf >= u * (4.0 - u) - 3.0) {
                    break;
                }
                if (u * (u - lf) > 1.0) {
                    continue;
                }
                if (2.0 * @log(u) <= lf) {
                    break;
                }
            }
            return k;
        }

        pub fn pmf(self: Self, k: I, lambda: F) I {
            return @exp(self.lnPmf(I, F, k, lambda));
        }

        pub fn lnPmf(k: I, lambda: F) I {
            return @as(F, @floatFromInt(k)) * @log(lambda) - lambda + spec_fn.lnFactorial(k);
        }
    };
}

test "Poisson API" {
    const DefaultPrng = std.rand.Xoshiro256;
    const seed: u64 = @intCast(std.time.milliTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var poisson = Poisson(u32, f64).init(&rng);
    var sum: f64 = 0.0;
    const lambda: f64 = 20.0;
    for (0..10_000) |_| {
        const samp = poisson.sample(lambda);
        sum += @as(f64, @floatFromInt(samp));
    }
    const avg: f64 = sum / 10_000.0;
    const mean: f64 = lambda;
    const variance: f64 = lambda;
    try std.testing.expectApproxEqAbs(
        mean, avg, variance
    );
}