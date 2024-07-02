const std = @import("std");
const Allocator = std.mem.Allocator;
const Random = std.Random;
const utils = @import("utils.zig");

/// Bernoulli distribution with parameter `p`.
///
/// [https://en.wikipedia.org/wiki/Bernoulli_distribution](https://en.wikipedia.org/wiki/Bernoulli_distribution)
pub fn Bernoulli(comptime I: type, comptime F: type) type {
    _ = utils.ensureIntegerType(I);
    _ = utils.ensureFloatType(F);

    return struct {
        rand: *Random,
        const Self = @This();

        pub fn init(rand: *Random) Self {
            return Self{ .rand = rand };
        }

        /// Generate a random sample from a Bernoulli distribution with
        /// probability of success `p`.
        pub fn sample(self: Self, p: F) I {
            if (p < 0.0 or p > 1.0) {
                @panic("Parameter `p` must be within the range 0 < p < 1.");
            }
            // Random floats can only be generated for f32 and f64
            const random_val: F = @floatCast(self.rand.float(f64));
            if (p < random_val) {
                return 0;
            } else {
                return 1;
            }
        }

        /// Generate a slice of random samples of length `size` from a Bernoulli distribution
        /// with probability of success `p`.
        pub fn sampleSlice(
            self: Self,
            size: usize,
            p: F,
            allocator: Allocator,
        ) ![]I {
            if (p < 0.0 or p > 1.0) {
                @panic("Parameter `p` must be within the range 0 < p < 1.");
            }
            var res = try allocator.alloc(I, size);
            for (0..size) |i| {
                res[i] = self.sample(p);
            }
            return res;
        }
    };
}

test "Sample Bernoulli" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var bernoulli = Bernoulli(u8, f64).init(&rand);
    const val = bernoulli.sample(0.4);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Bernoulli Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var bernoulli = Bernoulli(u8, f64).init(&rand);

    var allocator = std.testing.allocator;
    const sample = try bernoulli.sampleSlice(100, 0.4, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Bernoulli Mean" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var bernoulli = Bernoulli(u8, f64).init(&rand);

    const p_vec = [_]f64{ 0.05, 0.1, 0.2, 0.4, 0.5, 0.6, 0.8, 0.9, 0.95 };

    std.debug.print("\n", .{});
    for (p_vec) |p| {
        var samp: u8 = undefined;
        var sum: f64 = 0.0;
        for (0..10_000) |_| {
            samp = bernoulli.sample(p);
            sum += @as(f64, @floatFromInt(samp));
        }
        const mean: f64 = p;
        const avg: f64 = sum / 10_000.0;
        const variance: f64 = p * (1.0 - p);
        std.debug.print("Mean: {}\tAvg: {}\tStdDev {}\n", .{ mean, avg, @sqrt(variance) });
        try std.testing.expectApproxEqAbs(mean, avg, @sqrt(variance));
    }
}

test "Bernoulli with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const int_types = [_]type{ u8, u16, u32, u64, u128, i8, i16, i32, i64, i128 };
    const float_types = [_]type{ f32, f64, f128 };

    std.debug.print("\n", .{});
    inline for (int_types) |i| {
        inline for (float_types) |f| {
            var bernoulli = Bernoulli(i, f).init(&rand);
            const val = bernoulli.sample(0.25);
            std.debug.print("Bernoulli({any}, {any}):\t{}\n", .{ i, f, val });
        }
    }
}
