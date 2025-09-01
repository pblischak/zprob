const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const Binomial = @import("binomial.zig").Binomial;
const BinomialError = @import("binomial.zig").BinomialError;
const spec_fn = @import("special_functions.zig");
const utils = @import("utils.zig");

pub const MultinomialError = error{ProbSumNotOne} || BinomialError;

/// Multinomial distribution with parameters `n` (number of totol observations)
/// and `p_vec` (probability of observing each category).
///
/// [https://en.wikipedia.org/wiki/Multinomial_distribution](https://en.wikipedia.org/wiki/Multinomial_distribution)
pub fn Multinomial(comptime K: usize, comptime I: type, comptime F: type) type {
    _ = utils.ensureIntegerType(I);
    _ = utils.ensureFloatType(F);

    return struct {
        const Self = @This();
        const binomial = Binomial(I, F){};

        pub fn sample(
            self: Self,
            n: I,
            p_vec: [K]F,
            rand: *Random,
        ) MultinomialError![K]I {
            _ = self;
            if (!utils.sumToOne(F, p_vec[0..], @sqrt(math.floatEps(F)))) {
                return MultinomialError.ProbSumNotOne;
            }
            var out_vec: [K]I = undefined;

            var p_tot: F = 1.0;
            var n_tot = n;
            var prob: F = undefined;

            for (0..K) |i| {
                out_vec[i] = 0;
            }

            for (0..(K - 1)) |icat| {
                prob = p_vec[icat] / p_tot;
                out_vec[icat] = try binomial.sample(n_tot, prob, rand);
                n_tot -= out_vec[icat];
                if (n_tot <= 0) {
                    return out_vec;
                }
                p_tot -= p_vec[icat];
            }
            out_vec[K - 1] = n_tot;

            return out_vec;
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            n: I,
            p_vec: [K]F,
            rand: *Random,
            allocator: Allocator,
        ) (MultinomialError || Allocator.Error)![]I {
            var res = try allocator.alloc(I, K * size);
            var tmp: [K]I = undefined;
            var start: usize = 0;
            for (0..size) |i| {
                start = i * K;
                tmp = try self.sample(
                    n,
                    p_vec,
                    rand,
                );
                @memcpy(res[start..(start + K)], tmp[0..]);
            }
            return res;
        }

        pub fn pmf(
            self: Self,
            k_vec: [K]I,
            p_vec: [K]F,
        ) (MultinomialError || spec_fn.Error)!F {
            if (!utils.sumToOne(F, p_vec[0..], @sqrt(math.floatEps(F)))) {
                return MultinomialError.ProbSumNotOne;
            }
            return @exp(try self.lnPmf(k_vec, p_vec));
        }

        pub fn lnPmf(
            self: Self,
            k_vec: [K]I,
            p_vec: [K]F,
        ) (MultinomialError || spec_fn.Error)!F {
            if (!utils.sumToOne(F, p_vec[0..], @sqrt(math.floatEps(F)))) {
                return MultinomialError.ProbSumNotOne;
            }
            _ = self;
            var n: I = 0;
            for (k_vec[0..]) |x| {
                n += x;
            }

            var coeff: F = try spec_fn.lnFactorial(I, F, n);
            var probs: F = undefined;
            for (k_vec[0..], 0..) |k, i| {
                coeff -= try spec_fn.lnFactorial(I, F, k);
                probs += @as(F, @floatFromInt(k)) * @log(p_vec[i]);
            }
            return coeff + probs;
        }
    };
}

test "Sample Multinomial" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const multinomial = Multinomial(4, u32, f64){};
    const p_vec = [_]f64{ 0.1, 0.25, 0.35, 0.3 };
    const out_vec = try multinomial.sample(10, p_vec, &rand);
    std.debug.print("\n{any}\n", .{out_vec});
}

test "Sample Multinomial Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const multinomial = Multinomial(4, u32, f64){};
    const allocator = std.testing.allocator;
    const p_vec = [4]f64{ 0.1, 0.25, 0.35, 0.3 };
    const sample = try multinomial.sampleSlice(
        100,
        10,
        p_vec,
        &rand,
        allocator,
    );
    defer allocator.free(sample);
    std.debug.print("\n", .{});
    for (0..100) |i| {
        const start = i * p_vec.len;
        std.debug.print("{any}\n", .{sample[start..(start + p_vec.len)]});
    }
}

test "Multinomial Mean" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const multinomial = Multinomial(3, u32, f64){};

    const p_vecs = [_][3]f64{
        [3]f64{ 0.33, 0.33, 0.34 },
        [3]f64{ 0.1, 0.2, 0.7 },
        [3]f64{ 0.5, 0.25, 0.25 },
        [3]f64{ 0.8, 0.1, 0.1 },
        [3]f64{ 0.4, 0.35, 0.25 },
    };

    for (p_vecs) |p_vec| {
        var tmp: [3]u32 = [3]u32{ 0.0, 0.0, 0.0 };
        var avg_vec: [3]f64 = [3]f64{ 0.0, 0.0, 0.0 };
        for (0..10_000) |_| {
            tmp = try multinomial.sample(10, p_vec, &rand);
            avg_vec[0] += @floatFromInt(tmp[0]);
            avg_vec[1] += @floatFromInt(tmp[1]);
            avg_vec[2] += @floatFromInt(tmp[2]);
        }
        avg_vec[0] /= 10_000.0;
        avg_vec[1] /= 10_000.0;
        avg_vec[2] /= 10_000.0;

        const mean_vec = [_]f64{ 10.0 * p_vec[0], 10.0 * p_vec[1], 10.0 * p_vec[2] };
        const stddev_vec = [_]f64{
            @sqrt(10.0 * p_vec[0] * (1.0 - p_vec[0])),
            @sqrt(10.0 * p_vec[1] * (1.0 - p_vec[1])),
            @sqrt(10.0 * p_vec[2] * (1.0 - p_vec[2])),
        };

        std.debug.print(
            "Mean: {any}\nAvg: {any}\nStdDev: {any}\n\n",
            .{ mean_vec, avg_vec, stddev_vec },
        );
        for (0..3) |i| {
            try std.testing.expectApproxEqAbs(mean_vec[i], avg_vec[i], stddev_vec[i]);
        }
    }
}

test "Multinomial with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const int_types = [_]type{ u8, u16, u32, u64, u128, i8, i16, i32, i64, i128 };
    const float_types = [_]type{ f32, f64 };

    std.debug.print("\n", .{});
    inline for (int_types) |i| {
        inline for (float_types) |f| {
            const multinomial = Multinomial(4, i, f){};
            const p_vec = [4]f{ 0.1, 0.25, 0.35, 0.3 };
            const out_vec = try multinomial.sample(10, p_vec, &rand);
            std.debug.print(
                "Multinomial({any}, {any}): {any}\n",
                .{ i, f, out_vec },
            );
        }
    }
}
