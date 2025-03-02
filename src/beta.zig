const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const spec_fn = @import("special_functions.zig");
const utils = @import("utils.zig");
const Gamma = @import("gamma.zig").Gamma;

/// Beta distribution with parameters `alpha` > 0 and `beta` > 0.
///
/// [https://en.wikipedia.org/wiki/Beta_distribution](https://en.wikipedia.org/wiki/Beta_distribution)
pub fn Beta(comptime F: type) type {
    _ = utils.ensureFloatType(F);

    return struct {
        rand: *Random,
        gamma: Gamma(F),

        const Self = @This();
        const Error = error{
            AlphaLessThanZero,
            BetaLessThanZero,
            XOutOfRange,
        };

        /// Initializes a Beta struct with a pointer to a
        /// Pseudo-Random Number Generator.
        pub fn init(rand: *Random) Self {
            return Self{
                .rand = rand,
                .gamma = Gamma(F).init(rand),
            };
        }

        /// Generate a sample from a Beta distribution with parameters
        /// `alpha` > 0 and `beta` > 0. Invalid values passed as
        /// parameters will cause a panic.
        pub fn sample(self: Self, alpha: F, beta: F) Error!F {
            if (alpha <= 0) {
                return Error.AlphaLessThanZero;
            }
            if (beta <= 0) {
                return Error.BetaLessThanZero;
            }

            if (alpha <= 1.0 and beta <= 1.0) {
                var u: F = undefined;
                var v: F = undefined;
                var x: F = undefined;
                var y: F = undefined;

                while (true) {
                    u = @floatCast(self.rand.float(f64));
                    v = @floatCast(self.rand.float(f64));
                    x = @floatCast(math.pow(
                        f64,
                        @floatCast(u),
                        @floatCast(1.0 / alpha),
                    ));
                    y = @floatCast(math.pow(
                        f64,
                        @floatCast(u),
                        @floatCast(1.0 / beta),
                    ));

                    if ((x + y) <= 1.0) {
                        if ((x + y) > 0.0) {
                            return x / (x + y);
                        } else {
                            var log_x: F = @log(u) / alpha;
                            var log_y: F = @log(v) / beta;
                            const log_m: F = if (log_x > log_y) log_x else log_y;
                            log_x -= log_m;
                            log_y -= log_m;
                            return @exp(log_x - @log(@exp(log_x) + @exp(log_y)));
                        }
                    }
                }
            } else {
                const x1: F = self.gamma.sample(alpha, 1.0);
                const x2: F = self.gamma.sample(beta, 1.0);
                return x1 / (x1 + x2);
            }
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            alpha: F,
            beta: F,
            allocator: Allocator,
        ) (Error || Allocator.Error)![]F {
            var res = try allocator.alloc(F, size);
            for (0..size) |i| {
                res[i] = try self.sample(alpha, beta);
            }
            return res;
        }

        /// For a Beta random variable, X, with parameters `alpha` > 0
        /// and `beta` > 0, return the probability that X is less than
        /// some value 0 <= x <= 1.
        pub fn pdf(self: Self, x: F, alpha: F, beta: F) Error!F {
            _ = self;
            if (alpha <= 0) {
                return Error.AlphaLessThanZero;
            }
            if (beta <= 0) {
                return Error.BetaLessThanZero;
            }
            if (x < 0 or x > 1) {
                return Error.XOutOfRange;
            }

            var value: F = 0.0;
            if (x < 0.0 or x > 1.0) {
                value = 0.0;
            } else {
                const ln_beta: F = spec_fn.betaFn(F, alpha, beta);
                const first_term: F = @floatCast(math.pow(f64, @floatCast(x), @floatCast(alpha - 1.0)));
                const second_term: F = @floatCast(math.pow(f64, @floatCast(1.0 - x), @floatCast(beta - 1.0)));
                value = first_term * second_term / ln_beta;
            }

            return value;
        }

        pub fn lnPdf(self: Self, x: F, alpha: F, beta: F) !F {
            _ = self;
            if (alpha <= 0) {
                return Error.AlphaLessThanZero;
            }
            if (beta <= 0) {
                return Error.BetaLessThanZero;
            }
            if (x < 0 or x > 1) {
                return Error.XOutOfRange;
            }

            var value: F = 0.0;
            if (x < 0.0 or x > 1.0) {
                value = math.inf(F);
            } else {
                // zig fmt: off
                const ln_beta: F = spec_fn.lnBetaFn(F, alpha, beta);
                value = (alpha - 1.0) * @log(x)
                    + (beta - 1.0) * @log(1.0 - x)
                    - ln_beta;
                // zig fmt: on
            }

            return value;
        }
    };
}

test "Beta alpha <= 0" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.rand.Xoroshiro128.init(seed);
    var rand = prng.random();
    var beta = Beta(f64).init(&rand);

    const val1 = beta.sample(-1.0, 10.0);
    try std.testing.expectError(error.AlphaLessThanZero, val1);

    const val2 = beta.pdf(0.5, -1.0, 10.0);
    try std.testing.expectError(error.AlphaLessThanZero, val2);

    const val3 = beta.lnPdf(0.5, -1.0, 10.0);
    try std.testing.expectError(error.AlphaLessThanZero, val3);
}

test "Beta beta <= 0" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.rand.Xoroshiro128.init(seed);
    var rand = prng.random();
    var beta = Beta(f64).init(&rand);

    const val1 = beta.sample(1.0, -10.0);
    try std.testing.expectError(error.BetaLessThanZero, val1);

    const val2 = beta.pdf(0.5, 1.0, -10.0);
    try std.testing.expectError(error.BetaLessThanZero, val2);

    const val3 = beta.lnPdf(0.5, 1.0, -10.0);
    try std.testing.expectError(error.BetaLessThanZero, val3);
}

test "Beta x out of range" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.rand.Xoroshiro128.init(seed);
    var rand = prng.random();
    var beta = Beta(f64).init(&rand);

    const val1 = beta.pdf(-10.0, 1.0, 10.0);
    try std.testing.expectError(error.XOutOfRange, val1);

    const val2 = beta.pdf(10.0, 1.0, 10.0);
    try std.testing.expectError(error.XOutOfRange, val2);

    const val3 = beta.lnPdf(-10.0, 1.0, 10.0);
    try std.testing.expectError(error.XOutOfRange, val3);

    const val4 = beta.lnPdf(10.0, 1.0, 10.0);
    try std.testing.expectError(error.XOutOfRange, val4);
}

test "Sample Beta" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.rand.Xoroshiro128.init(seed);
    var rand = prng.random();
    var beta = Beta(f64).init(&rand);

    const val = try beta.sample(2.0, 5.0);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Beta Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.rand.Xoroshiro128.init(seed);
    var rand = prng.random();
    var beta = Beta(f64).init(&rand);

    const allocator = std.testing.allocator;
    const sample = try beta.sampleSlice(100, 2.0, 5.0, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Beta Mean" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.rand.Xoroshiro128.init(seed);
    var rand = prng.random();
    var beta = Beta(f64).init(&rand);

    const alpha_vec = [_]f64{ 0.05, 0.5, 1.0, 5.0, 10.0, 20.0, 50.0 };
    const beta_vec = [_]f64{ 0.05, 0.5, 1.0, 5.0, 10.0, 20.0, 50.0 };

    std.debug.print("\n", .{});
    for (alpha_vec) |a| {
        for (beta_vec) |b| {
            var samp: f64 = undefined;
            var sum: f64 = 0.0;
            for (0..10_000) |_| {
                samp = try beta.sample(a, b);
                sum += samp;
            }

            const mean: f64 = a / (a + b);
            const avg: f64 = sum / 10_000;
            const variance: f64 = (a * b) / ((a + b) * (a + b) * (a + b + 1.0));
            std.debug.print(
                "Mean: {}\tAvg: {}\tStdDev {}\n",
                .{ mean, avg, @sqrt(variance) },
            );
            try std.testing.expectApproxEqAbs(mean, avg, @sqrt(variance));
        }
    }
}

test "Beta with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.rand.Xoroshiro128.init(seed);
    var rand = prng.random();

    const float_types = [_]type{ f32, f64 };

    std.debug.print("\n", .{});
    inline for (float_types) |f| {
        var beta = Beta(f).init(&rand);
        const val = try beta.sample(5.0, 2.0);
        std.debug.print("Beta({any}):\t{}\n", .{ f, val });
        const pdf = try beta.pdf(0.3, 5.0, 2.0);
        std.debug.print("BetaPdf({any}):\t{}\n", .{ f, pdf });
        const ln_pdf = try beta.lnPdf(0.3, 5.0, 2.0);
        std.debug.print("BetaLnPdf({any}):\t{}\n", .{ f, ln_pdf });
    }
}
