//! Uniform and UniformInt distributions
//!
//! Contiuous: [https://en.wikipedia.org/wiki/Continuous_uniform_distribution](https://en.wikipedia.org/wiki/Continuous_uniform_distribution)
//! Discrete [https://en.wikipedia.org/wiki/Discrete_uniform_distribution](https://en.wikipedia.org/wiki/Discrete_uniform_distribution)

const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const utils = @import("utils.zig");

/// Continuous Uniform distribution with parameters `low` and `high`.
pub fn Uniform(comptime F: type) type {
    _ = utils.ensureFloatType(F);

    return struct {
        const Self = @This();

        rand: *Random,

        pub fn init(rand: *Random) Self {
            return Self{
                .rand = rand,
            };
        }

        pub fn sample(self: Self, low: F, high: F) F {
            const u: F = @floatCast(self.rand.float(f64));
            return low + (high - low) * u;
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            low: F,
            high: F,
            allocator: Allocator,
        ) ![]F {
            var res = try allocator.alloc(F, size);
            for (0..size) |i| {
                res[i] = self.sample(low, high);
            }
            return res;
        }
    };
}

/// Discrete Uniform distribution with parameters `low` and `high`.
pub fn UniformInt(comptime I: type) type {
    _ = utils.ensureIntegerType(I);

    return struct {
        const Self = @This();

        rand: *Random,

        pub fn init(rand: *Random) Self {
            return Self{
                .rand = rand,
            };
        }

        pub fn sample(self: Self, low: I, high: I) I {
            return self.rand.intRangeAtMost(I, low, high);
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            low: I,
            high: I,
            allocator: Allocator,
        ) ![]I {
            var res = try allocator.alloc(I, size);
            for (0..size) |i| {
                res[i] = self.sample(low, high);
            }
            return res;
        }
    };
}

test "Sample Uniform" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var uniform = Uniform(f64).init(&rand);
    const val = uniform.sample(1.0, 10.0);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Uniform Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var uniform = Uniform(f64).init(&rand);
    const allocator = std.testing.allocator;
    const sample = try uniform.sampleSlice(100, 1.0, 10.0, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Uniform Mean" {
    const seed: u64 = @intCast(std.time.milliTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var uniform = Uniform(f64).init(&rand);

    const range_vec = [_][2]f64{
        [2]f64{ 0.0, 2.0 },
        [2]f64{ 10.0, 20.0 },
        [2]f64{ 1.0, 5.0 },
        [2]f64{ -1.5, 2.0 },
        [2]f64{ -5.0, 20.0 },
    };

    std.debug.print("\n", .{});
    for (range_vec) |range| {
        var sum: f64 = 0.0;
        for (0..10_000) |_| {
            const samp = uniform.sample(range[0], range[1]);
            sum += samp;
        }
        const mean: f64 = (range[1] + range[0]) / 2.0;
        const avg: f64 = sum / 10_000.0;
        const variance: f64 = (range[1] - range[0]) * (range[1] - range[0]) / 12.0;
        std.debug.print("Mean: {}\tAvg: {}\tStdDev: {}\n", .{ mean, avg, @sqrt(variance) });
        try std.testing.expectApproxEqAbs(mean, avg, @sqrt(variance));
    }
}

test "Uniform with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const float_types = [_]type{ f32, f64, f128 };

    std.debug.print("\n", .{});
    inline for (float_types) |f| {
        var uniform = Uniform(f).init(&rand);
        const val = uniform.sample(1.0, 10.0);
        std.debug.print(
            "Uniform({any}): {}\n",
            .{ f, val },
        );
    }
}

test "Sample Uniform Int" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var uniform_int = UniformInt(i32).init(&rand);
    const val = uniform_int.sample(1, 10);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Uniform Int Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var uniform_int = UniformInt(i32).init(&rand);
    const allocator = std.testing.allocator;
    const sample = try uniform_int.sampleSlice(100, 1, 10, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Uniform Int Mean" {
    const seed: u64 = @intCast(std.time.milliTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var uniform_int = UniformInt(i32).init(&rand);

    const range_vec = [_][2]i32{
        [2]i32{ 0, 2 },
        [2]i32{ 10, 20 },
        [2]i32{ 1, 5 },
        [2]i32{ -1, 2 },
        [2]i32{ -5, 20 },
    };

    std.debug.print("\n", .{});
    for (range_vec) |range| {
        var sum: f64 = 0.0;
        for (0..10_000) |_| {
            const samp = @as(f64, @floatFromInt(uniform_int.sample(range[0], range[1])));
            sum += samp;
        }
        const mean: f64 = @as(f64, @floatFromInt(range[1] + range[0])) / 2.0;
        const avg: f64 = sum / 10_000.0;
        const first_term: f64 = @floatFromInt(range[1] - range[0] + 1);
        const variance: f64 = (first_term * first_term - 1.0) / 12.0;
        std.debug.print("Mean: {}\tAvg: {}\tStdDev: {}\n", .{ mean, avg, @sqrt(variance) });
        try std.testing.expectApproxEqAbs(mean, avg, @sqrt(variance));
    }
}

test "Uniform Int with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const int_types = [_]type{ u8, u16, u32, u64, u128, i16, i32, i64, i128 };

    std.debug.print("\n", .{});
    inline for (int_types) |i| {
        var uniform_int = UniformInt(i).init(&rand);
        const val = uniform_int.sample(1, 10);
        std.debug.print(
            "Uniform({any}): {}\n",
            .{ i, val },
        );
    }
}
