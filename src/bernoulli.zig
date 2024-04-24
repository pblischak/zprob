const std = @import("std");
const Allocator = std.mem.Allocator;
const Random = std.rand.Random;
const utils = @import("utils.zig");

/// Bernoulli distribution with parameter `p`.
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
            // const random_val = self.prng.float(F);
            const random_val = self.rand.float(F);
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
            var res = try allocator.alloc(I, size);
            for (0..size) |i| {
                res[i] = self.sample(p);
            }
            return res;
        }
    };
}

test "Sample Bernoulli" {
    var seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.rand.Xoroshiro128.init(seed);
    var rand = prng.random();
    var bernoulli = Bernoulli(u8, f64).init(&rand);
    const val = bernoulli.sample(0.4);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Bernoulli Slice" {
    var seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.rand.Xoroshiro128.init(seed);
    var rand = prng.random();
    var bernoulli = Bernoulli(u8, f64).init(&rand);

    var allocator = std.testing.allocator;
    const sample = try bernoulli.sampleSlice(100, 0.4, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Bernoulli Mean" {
    var seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.rand.Xoroshiro128.init(seed);
    var rand = prng.random();
    var bernoulli = Bernoulli(u8, f64).init(&rand);

    const p: f64 = 0.2;
    var samp: u8 = undefined;
    var sum: f64 = 0.0;
    for (0..10_000) |_| {
        samp = bernoulli.sample(p);
        sum += @as(f64, @floatFromInt(samp));
    }
    const mean: f64 = p;
    const avg: f64 = sum / 10_000.0;
    const variance: f64 = p * (1.0 - p);
    std.debug.print("Mean: {}\tAvg: {}\tVariance {}\n", .{ mean, avg, variance });
    try std.testing.expectApproxEqAbs(mean, avg, variance);
}
