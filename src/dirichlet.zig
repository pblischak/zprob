const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const Gamma = @import("gamma.zig").Gamma;
const GammaError = @import("gamma.zig").GammaError;
const spec_fn = @import("special_functions.zig");
const utils = @import("utils.zig");

/// Dirichlet distribution with parameter `alpha_vec`.
///
/// [https://en.wikipedia.org/wiki/Dirichlet_distribution](https://en.wikipedia.org/wiki/Dirichlet_distribution)
pub fn Dirichlet(comptime K: usize, comptime F: type) type {
    _ = utils.ensureFloatType(F);

    return struct {
        rand: *Random,
        gamma: Gamma(F),

        const Self = @This();
        const Error = GammaError;

        pub fn init(rand: *Random) Self {
            return Self{
                .rand = rand,
                .gamma = Gamma(F).init(rand),
            };
        }

        pub fn sample(self: Self, alpha_vec: [K]F) Error![K]F {
            var sum: F = 0.0;
            var out: [K]F = [_]F{0.0} ** K;
            for (alpha_vec, 0..) |alpha, i| {
                out[i] = try self.gamma.sample(alpha, 1.0);
                sum += out[i];
            }

            for (out[0..]) |*x| {
                x.* /= sum;
            }

            return out;
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            alpha_vec: [K]F,
            allocator: Allocator,
        ) (Error || Allocator.Error)![]F {
            var res = try allocator.alloc(F, size * K);
            var tmp: [K]F = undefined;
            var start: usize = 0;
            for (0..size) |i| {
                start = i * K;
                tmp = try self.sample(alpha_vec);
                @memcpy(res[start..(start + K)], tmp[0..]);
            }
            return res;
        }

        pub fn pdf(self: Self, x_vec: [K]F, alpha_vec: [K]F) F {
            const val = self.lnPdf(x_vec, alpha_vec);
            return @exp(val);
        }

        pub fn lnPdf(self: Self, x_vec: [K]F, alpha_vec: [K]F) F {
            _ = self;
            var numerator: F = 0.0;

            for (x_vec, 0..) |x, i| {
                numerator += (alpha_vec[i] - 1.0) * @log(x);
            }

            const ln_multi_beta = lnMultivariateBeta(F, alpha_vec[0..]);
            return numerator - ln_multi_beta;
        }
    };
}

fn multivariateBeta(comptime F: type, alpha_vec: []const F) F {
    return @exp(lnMultivariateBeta(F, alpha_vec));
}

fn lnMultivariateBeta(comptime F: type, alpha_vec: []const F) F {
    var numerator: F = undefined;
    var alpha_sum: F = 0.0;

    for (alpha_vec) |alpha| {
        numerator += math.lgamma(F, alpha);
        alpha_sum += alpha;
    }

    const ln_gamma = math.lgamma(F, alpha_sum);
    return numerator - ln_gamma;
}

test "Sample Dirichlet" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var dirichlet = Dirichlet(4, f64).init(&rand);
    const alphas = [4]f64{ 1.0, 2.0, 5.0, 10.0 };
    const out_vec = dirichlet.sample(alphas);
    std.debug.print("\n{any}\n", .{out_vec});
}

test "Sample Dirichlet Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    const allocator = std.testing.allocator;

    var dirichlet = Dirichlet(4, f64).init(&rand);
    const alphas = [4]f64{ 1.0, 2.0, 5.0, 10.0 };
    const sample = try dirichlet.sampleSlice(100, alphas, allocator);
    defer allocator.free(sample);
    std.debug.print("\n", .{});
    for (0..100) |i| {
        const start = i * alphas.len;
        std.debug.print(
            "{}: {any}\n",
            .{ i + 1, sample[start..(start + alphas.len)] },
        );
    }
}

test "Dirichlet Mean" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var dirichlet = Dirichlet(3, f64).init(&rand);
    const alpha_vecs = [_][3]f64{
        [_]f64{ 0.1, 0.1, 0.1 },
        [_]f64{ 1.0, 1.0, 1.0 },
        [_]f64{ 2.0, 5.0, 10.0 },
        [_]f64{ 10.0, 5.0, 2.0 },
        [_]f64{ 10.0, 2.0, 20.0 },
    };

    std.debug.print("\n", .{});
    for (alpha_vecs) |alpha_vec| {
        // const alpha_sum = 0.3;
        var tmp: [3]f64 = [3]f64{ 0.0, 0.0, 0.0 };
        var avg_vec: [3]f64 = [3]f64{ 0.0, 0.0, 0.0 };
        for (0..10_000) |_| {
            tmp = try dirichlet.sample(alpha_vec);
            avg_vec[0] += tmp[0];
            avg_vec[1] += tmp[1];
            avg_vec[2] += tmp[2];
        }
        avg_vec[0] /= 10_000.0;
        avg_vec[1] /= 10_000.0;
        avg_vec[2] /= 10_000.0;

        const alpha0: f64 = alpha_vec[0] + alpha_vec[1] + alpha_vec[2];
        var mean_vec = [3]f64{ 0.0, 0.0, 0.0 };
        var stddev_vec = [3]f64{ 0.0, 0.0, 0.0 };
        for (alpha_vec, 0..) |alpha, i| {
            const alpha_bar = alpha / alpha0;
            mean_vec[i] = alpha_bar;
            stddev_vec[i] = @sqrt((alpha_bar * (1.0 - alpha_bar)) / (alpha0 + 1.0));
        }
        std.debug.print(
            "Mean: {any}\nAvg: {any}\nStdDev: {any}\n\n",
            .{ mean_vec, avg_vec, stddev_vec },
        );
        for (0..3) |i| {
            try std.testing.expectApproxEqAbs(mean_vec[i], avg_vec[i], stddev_vec[i]);
        }
    }
}

test "Dirichlet with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const float_types = [_]type{ f32, f64 };

    std.debug.print("\n", .{});
    inline for (float_types) |f| {
        var dirichlet = Dirichlet(4, f).init(&rand);
        const alphas = [4]f{ 1.0, 2.0, 5.0, 10.0 };
        const out_vec = try dirichlet.sample(alphas);
        std.debug.print("Dirichlet({any}): {any}\n", .{ f, out_vec });
    }
}
