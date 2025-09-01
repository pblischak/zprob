const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const Gamma = @import("gamma.zig").Gamma;
const GammaError = @import("gamma.zig").GammaError;
const Poisson = @import("poisson.zig").Poisson;
const PoissonError = @import("poisson.zig").PoissonError;
const spec_fn = @import("special_functions.zig");
const utils = @import("utils.zig");

pub const NegativeBinomialError = error{
    BadNumSuccesses,
    BadProbSuccess,
} || GammaError || PoissonError;

/// Negative binomial distribution with parameters `p` (probability of success)
///  and `r` (number of successes).
///
/// [https://en.wikipedia.org/wiki/Negative_binomial_distribution](https://en.wikipedia.org/wiki/Negative_binomial_distribution)
pub fn NegativeBinomial(comptime I: type, comptime F: type) type {
    _ = utils.ensureIntegerType(I);
    _ = utils.ensureFloatType(F);

    return struct {
        const Self = @This();
        const poisson = Poisson(I, F){};
        const gamma = Gamma(F){};

        fn check(r: I, p: F) NegativeBinomialError!void {
            if (r <= 0) {
                return NegativeBinomialError.BadNumSuccesses;
            }

            if (p <= 0.0 or 1.0 <= p) {
                return NegativeBinomialError.BadProbSuccess;
            }
        }

        pub fn sample(self: Self, r: I, p: F, rand: *Random) NegativeBinomialError!I {
            _ = self;
            try check(r, p);
            const r_f = @as(F, @floatFromInt(r));
            var a: F = undefined;
            var y: F = undefined;
            var value: I = undefined;

            a = (1.0 - p) / p;
            y = try gamma.sample(a, r_f, rand);
            value = try poisson.sample(y, rand);

            return value;
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            r: I,
            p: F,
            rand: *Random,
            allocator: Allocator,
        ) (NegativeBinomialError || Allocator.Error)![]I {
            try check(r, p);
            var res = try allocator.alloc(I, size);
            for (0..size) |i| {
                res[i] = try self.sample(r, p, rand);
            }
            return res;
        }

        pub fn pmf(self: Self, k: I, r: I, p: F) !F {
            return @exp(try self.lnPmf(k, r, p));
        }

        pub fn lnPmf(self: Self, k: I, r: I, p: F) !F {
            _ = self;
            const k_f = @as(F, @floatFromInt(k));
            const r_f = @as(F, @floatFromInt(r));
            const coeff = try spec_fn.lnNChooseK(I, F, k + r - 1, k);
            return coeff + k_f * @log(1.0 - p) + r_f * @log(p);
        }
    };
}

test "Sample Negative Binomial" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const neg_binomial = NegativeBinomial(u32, f64){};
    const val = try neg_binomial.sample(10, 0.9, &rand);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Negative Binomial Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const neg_binomial = NegativeBinomial(u32, f64){};
    const allocator = std.testing.allocator;
    const sample = try neg_binomial.sampleSlice(100, 10, 0.9, &rand, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Negative Binomial Mean" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const neg_binomial = NegativeBinomial(u32, f64){};

    const p_vec = [_]f64{ 0.5, 0.1, 0.2, 0.4, 0.5, 0.6, 0.8, 0.9, 0.95 };

    std.debug.print("\n", .{});
    for (p_vec) |p| {
        var sum: u32 = 0;
        for (0..10_000) |_| {
            sum += try neg_binomial.sample(10, p, &rand);
        }
        const mean = 10.0 * (1.0 - p) / p;
        const variance = 10.0 * (1.0 - p) / p / p;
        const avg = @as(f64, @floatFromInt(sum)) / 10_000.0;
        std.debug.print(
            "Mean: {}\tAvg: {}\tStdDev: {}\n",
            .{ mean, avg, @sqrt(variance) },
        );
        try std.testing.expectApproxEqAbs(mean, avg, @sqrt(variance));
    }
}

test "Negative Binomial with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const int_types = [_]type{ u8, u16, u32, u64, u128, i8, i16, i32, i64, i128 };
    const float_types = [_]type{ f32, f64 };

    std.debug.print("\n", .{});
    inline for (int_types) |i| {
        inline for (float_types) |f| {
            const neg_binomial = NegativeBinomial(i, f){};
            const val = try neg_binomial.sample(10, 0.9, &rand);
            std.debug.print(
                "NegativeBinomial({any}, {any}): {}\n",
                .{ i, f, val },
            );
        }
    }
}
