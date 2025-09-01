const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const Gamma = @import("gamma.zig").Gamma;
const GammaError = @import("gamma.zig").GammaError;
const utils = @import("utils.zig");

/// Chi-squared distribution with degrees of freedom `k`.
///
/// [https://en.wikipedia.org/wiki/Chi-squared_distribution](https://en.wikipedia.org/wiki/Chi-squared_distribution)
pub fn ChiSquared(comptime I: type, comptime F: type) type {
    _ = utils.ensureIntegerType(I);
    _ = utils.ensureFloatType(F);

    return struct {
        const Self = @This();
        const Error = GammaError;
        const gamma = Gamma(F){};

        pub fn sample(self: Self, k: I, rand: *Random) Error!F {
            _ = self;
            const b: F = @as(F, @floatFromInt(k)) / 2.0;
            const k_usize: usize = @intCast(k);

            var x2: F = undefined;
            var x: F = undefined;
            if (k <= 100) {
                x2 = 0.0;
                for (0..k_usize) |_| {
                    x = @floatCast(rand.floatNorm(f64));
                    x2 += x * x;
                }
            } else {
                x2 = try gamma.sample(b, 0.5, rand);
            }

            return x2;
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            k: I,
            rand: *Random,
            allocator: Allocator,
        ) (Error || Allocator.Error)![]F {
            var res = try allocator.alloc(F, size);
            for (0..size) |i| {
                res[i] = try self.sample(k, rand);
            }
            return res;
        }

        pub fn pdf(self: Self, x: F, k: I) !F {
            if (x <= 0.0) {
                return 0.0;
            }

            const val = try self.lnPdf(x, k);
            return @exp(val);
        }

        pub fn lnPdf(self: Self, x: F, k: I) !F {
            _ = self;
            const b: F = @as(F, @floatFromInt(k)) / 2.0;
            const gamma_val = math.lgamma(F, b);
            return -(b * @log(2.0) + gamma_val) - b + (b - 1.0) * @log(x);
        }
    };
}

test "Sample Chi-Squared" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const chi_squared = ChiSquared(u32, f64){};
    const val = try chi_squared.sample(10, &rand);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Chi-Squared Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const chi_squared = ChiSquared(u32, f64){};
    const allocator = std.testing.allocator;
    const sample = try chi_squared.sampleSlice(100, 10, &rand, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Chi-squared Mean" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    const chi_squared = ChiSquared(u32, f64){};

    const k_vec = [_]u32{ 1, 2, 5, 10, 20 };

    std.debug.print("\n", .{});
    for (k_vec) |k| {
        var sum: f64 = 0.0;
        for (0..10_000) |_| {
            sum += try chi_squared.sample(@intCast(k), &rand);
        }
        const mean = @as(f64, @floatFromInt(k));
        const avg = sum / 10_000.0;
        const variance = @as(f64, @floatFromInt(2 * k));
        std.debug.print(
            "Mean: {}\tAvg: {}\tStdDev: {}\n",
            .{ mean, avg, @sqrt(variance) },
        );
        try std.testing.expectApproxEqAbs(mean, avg, @sqrt(variance));
    }
}

test "Chi-Squared with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const int_types = [_]type{ u8, u16, u32, u64, u128, i8, i16, i32, i64, i128 };
    const float_types = [_]type{ f32, f64 };

    std.debug.print("\n", .{});
    inline for (int_types) |i| {
        inline for (float_types) |f| {
            const chi_squared = ChiSquared(i, f){};
            const val = try chi_squared.sample(10, &rand);
            std.debug.print("ChiSquared({any}, {any}):\t{}\n", .{ i, f, val });
        }
    }
}
