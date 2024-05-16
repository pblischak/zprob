//! Normal distribution
//!
//! [https://en.wikipedia.org/wiki/Normal_distribution](https://en.wikipedia.org/wiki/Normal_distribution)

const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const utils = @import("utils.zig");

/// Normal distribution with parameters `mu` (mean) and `sigma` (standard deviation).
pub fn Normal(comptime F: type) type {
    _ = utils.ensureFloatType(F);

    return struct {
        const Self = @This();

        rand: *Random,

        pub fn init(rand: *Random) Self {
            return Self{
                .rand = rand,
            };
        }

        pub fn sample(self: Self, mu: F, sigma: F) F {
            const value: F = @floatCast(self.rand.floatNorm(f64));
            return value * sigma + mu;
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            mu: F,
            sigma: F,
            allocator: Allocator,
        ) ![]F {
            var res = try allocator.alloc(F, size);
            for (0..size) |i| {
                res[i] = self.sample(mu, sigma);
            }
            return res;
        }

        pub fn pdf(self: Self, mu: F, sigma: F, x: F) F {
            _ = self;
            // zig fmt: off
            return 1.0 / (sigma * @sqrt(2.0 * math.pi))
                * @exp(-(1.0 / 2.0) * math.pow(F, (x - mu) / sigma, 2));
            // zig fmt: on
        }

        pub fn lnPdf(self: Self, x: F, mu: F, sigma: F) F {
            _ = self;
            return -@log(sigma * @sqrt(2.0 * math.pi)) + math.pow(F, (x - mu) / sigma, 2);
        }
    };
}

test "Sample Normal" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var normal = Normal(f64).init(&rand);
    const val = normal.sample(2.0, 0.5);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Normal Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var normal = Normal(f64).init(&rand);
    const allocator = std.testing.allocator;
    const sample = try normal.sampleSlice(100, 2.0, 0.5, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Normal Mean" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var normal = Normal(f64).init(&rand);

    const mu_vec = [_]f64{ 0.1, 0.5, 2.0, 5.0, 10.0, 20.0, 50.0 };
    const sigma_vec = [_]f64{ 0.5, 1.0, 2.0, 5.0 };

    std.debug.print("\n", .{});
    for (mu_vec) |mu| {
        for (sigma_vec) |sigma| {
            var sum: f64 = 0.0;
            for (0..10_000) |_| {
                sum += normal.sample(mu, sigma);
            }
            const avg = sum / 10_000.0;
            std.debug.print(
                "Mean: {}\tAvg: {}\tStdDev: {}\n",
                .{ mu, avg, sigma },
            );
            try std.testing.expectApproxEqAbs(mu, avg, sigma);
        }
    }
}

test "Normal with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.rand.Xoroshiro128.init(seed);
    var rand = prng.random();

    const float_types = [_]type{ f32, f64, f128 };

    std.debug.print("\n", .{});
    inline for (float_types) |f| {
        var normal = Normal(f).init(&rand);
        const val = normal.sample(2.0, 0.5);
        std.debug.print("Normal({any}):\t{}\n", .{ f, val });
    }
}
