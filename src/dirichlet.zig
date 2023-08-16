//! Dirichlet distribution with parameter `alpha_vec`.

// zig fmt: off

const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;
const test_allocator = std.testing.allocator;

const Gamma = @import("gamma.zig").Gamma;
const spec_fn = @import("special_functions.zig");

pub fn Dirichlet(comptime F: type) type {
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

        pub fn sample(self: Self, alpha_vec: []const F, out_vec: []F) void {
            var sum: F = 0.0;
            for (alpha_vec, 0..) |alpha, i| {
                out_vec[i] = self.gamma.sample(alpha, 1.0);
                sum += out_vec[i];
            }

            for (out_vec) |*x| {
                x.* /= sum;
            }
        }

        pub fn pdf(self: Self, x_vec: []F, alpha_vec: []F) F {
            return @exp(self.lnPdf(x_vec, alpha_vec));
        }

        pub fn lnPdf(x_vec: []F, alpha_vec: []F) F {
            var numerator: F = 0.0;

            for (x_vec, 0..) |x, i| {
                numerator += (alpha_vec[i] - 1.0) * @log(x);
            }

            return numerator - lnMultivariateBeta(F, alpha_vec);
        }
    };
}

fn lnMultivariateBeta(comptime F: type, alpha_vec: []F) F {
    var numerator: F = undefined;
    var alpha_sum: F = 0.0;

    for (alpha_vec) |alpha| {
        numerator += spec_fn.lnGammaFn(F, alpha);
        alpha_sum += alpha;
    }

    return numerator - spec_fn.lnGammaFn(F, alpha_sum);
}

fn multivariateBeta(comptime F: type, alpha_vec: []F) F {
    return @exp(lnMultivariateBeta(F, alpha_vec));
}

test "Dirichlet API" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var dirichlet = Dirichlet(f64).init(*rng);
    var alpha_vec = [3]f64{ 0.1, 0.1, 0.1 };
    // const alpha_sum = 0.3;
    var tmp: [3]f64 = [3]f64{ 0.0, 0.0, 0.0 };
    var res: [3]f64 = [3]f64{ 0.0, 0.0, 0.0 };
    for (0..10_000) |_| {
        tmp = dirichlet.sample(alpha_vec[0..], tmp[0..]);
        defer test_allocator.free(tmp);
        res[0] += tmp[0];
        res[1] += tmp[1];
        res[2] += tmp[2];
    }
    res[0] /= 10_000.0;
    res[1] /= 10_000.0;
    res[2] /= 10_000.0;
    std.debug.print("\n{any}\n", .{res});
}