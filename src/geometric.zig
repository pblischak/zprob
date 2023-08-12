//! Geometric distribution with parameter `p`.
//!
//! Records the number of failures before the first success.

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

pub fn Geometric(comptime I: type, comptime F: type) type {
    return struct {
        const Self = @This();
        prng: *Random,

        pub fn init(prng: *Random) Self {
            return Self{
                .prng = prng,
            };
        }

        pub fn sample(self: Self, p: F) I {
            const u: F = self.prng.float(F);
            return @as(I, @intFromFloat(@log(u) / @log(1.0 - p))) + 1;
        }

        pub fn pmf(k: I, p: F) F {
            return @exp(lnPmf(I, F, k, p));
        }

        pub fn lnPmf(k: I, p: F) F {
            return @as(F, k) * @log(1.0 - p) + @log(p);
        }
    };
}

test "Geometric API" {
    const seed: u64 = @intCast(std.time.milliTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var geometric = Geometric(u32, f64).init(&rng);
    var sum: f64 = 0.0;
    const p: f64 = 0.01;
    var samp: u32 = undefined;
    for (0..10_000) |_| {
        samp = geometric.sample(p);
        sum += @as(f64, @floatFromInt(samp));
    }
    const avg: f64 = sum / 10_000.0;
    const mean: f64 = (1.0 - p) / p;
    const variance: f64 = (1.0 - p) / (p * p);
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        mean, avg, variance
    );
}
