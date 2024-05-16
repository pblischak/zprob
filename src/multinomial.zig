//! Multinomial distribution
//!
//! [https://en.wikipedia.org/wiki/Multinomial_distribution](https://en.wikipedia.org/wiki/Multinomial_distribution)

const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const Binomial = @import("binomial.zig").Binomial;
const spec_fn = @import("special_functions.zig");
const utils = @import("utils.zig");

/// Multinomial distribution with parameters `n` (number of totol observations)
/// and `p_vec` (probability of observing each category).
pub fn Multinomial(comptime I: type, comptime F: type) type {
    _ = utils.ensureIntegerType(I);
    _ = utils.ensureFloatType(F);

    return struct {
        const Self = @This();

        rand: *Random,

        pub fn init(rand: *Random) Self {
            return Self{
                .rand = rand,
            };
        }

        pub fn sample(
            self: Self,
            n: I,
            p_vec: []const F,
            out_vec: []I,
        ) void {
            const n_cat: usize = p_vec.len;
            if (p_vec.len != out_vec.len) {
                @panic("Length of probability and output vectors are not the same...");
            }

            if (!utils.sumToOne(F, p_vec, @sqrt(math.floatEps(F)))) {
                @panic("Probabilities in p_vec do not sum to 1.0...");
            }

            var p_tot: F = 1.0;
            var n_tot = n;
            var prob: F = undefined;

            for (0..n_cat) |i| {
                out_vec[i] = 0;
            }

            var binomial = Binomial(I, F).init(self.rand);

            for (0..(n_cat - 1)) |icat| {
                prob = p_vec[icat] / p_tot;
                out_vec[icat] = binomial.sample(n_tot, prob);
                n_tot -= out_vec[icat];
                if (n_tot <= 0) {
                    return;
                }
                p_tot -= p_vec[icat];
            }
            out_vec[n_cat - 1] = n_tot;
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            n: I,
            p_vec: []const F,
            allocator: Allocator,
        ) ![]I {
            const n_cat = p_vec.len;
            var res = try allocator.alloc(I, n_cat * size);
            var start: usize = 0;
            for (0..size) |i| {
                start = i * n_cat;
                self.sample(n, p_vec, res[start..(start + n_cat)]);
            }
            return res;
        }

        pub fn pmf(self: Self, k_vec: []const I, p_vec: []const F) F {
            return @exp(self.lnPmf(k_vec, p_vec));
        }

        pub fn lnPmf(self: Self, k_vec: []const I, p_vec: []const F) F {
            _ = self;
            var n: I = 0;
            for (k_vec) |x| {
                n += x;
            }

            var coeff: F = spec_fn.lnFactorial(I, F, n);
            var probs: F = undefined;
            for (k_vec, 0..) |k, i| {
                coeff -= spec_fn.lnFactorial(I, F, k);
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

    var multinomial = Multinomial(u32, f64).init(&rand);
    var p_vec = [_]f64{ 0.1, 0.25, 0.35, 0.3 };
    var out_vec = [_]u32{ 0, 0, 0, 0 };
    multinomial.sample(10, p_vec[0..], out_vec[0..]);
    std.debug.print("\n{any}\n", .{out_vec});
}

test "Sample Multinomial Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var multinomial = Multinomial(u32, f64).init(&rand);
    const allocator = std.testing.allocator;
    var p_vec = [_]f64{ 0.1, 0.25, 0.35, 0.3 };
    const sample = try multinomial.sampleSlice(
        100,
        10,
        p_vec[0..],
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

    var multinomial = Multinomial(u32, f64).init(&rand);

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
            multinomial.sample(10, p_vec[0..], tmp[0..]);
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
    const float_types = [_]type{ f32, f64, f128 };

    std.debug.print("\n", .{});
    inline for (int_types) |i| {
        inline for (float_types) |f| {
            var multinomial = Multinomial(i, f).init(&rand);
            var p_vec = [_]f{ 0.1, 0.25, 0.35, 0.3 };
            var out_vec = [_]i{ 0, 0, 0, 0 };
            multinomial.sample(10, p_vec[0..], out_vec[0..]);
            std.debug.print(
                "Multinomial({any}, {any}): {any}\n",
                .{ i, f, out_vec },
            );
        }
    }
}
