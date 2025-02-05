const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const utils = @import("utils.zig");

pub fn Weighted(comptime T: type, comptime F: type) type {
    _ = utils.ensureFloatType(F);

    return struct {
        const Self = @This();

        rand: *Random,

        pub fn init(rand: *Random) Self {
            return Self{
                .rand = rand,
            };
        }

        pub fn sample(self: Self, items: []const T, weights: []const F) T {
            assert(items.len == weights.len);
            assert(utils.sumToOne(F, weights, 1.0e-6));
            const u: F = @floatCast(self.rand.float(f64));

            var lower_bound: F = 0.0;
            for (0..(items.len - 1)) |i| {
                if (u > lower_bound and u < lower_bound + weights[i]) {
                    return items[i];
                }
                lower_bound += weights[i];
            }
            return items[items.len - 1];
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            items: []const T,
            weights: []const F,
            allocator: Allocator,
        ) ![]T {
            assert(items.len == weights.len);
            assert(utils.sumToOne(F, weights, 1.0e-6));
            var res = try allocator.alloc(T, size);
            for (0..size) |i| {
                res[i] = self.sample(items, weights);
            }
            return res;
        }
    };
}

test "Sample Weighted UInts" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.Xoroshiro128.init(seed);
    var rand = prng.random();
    var weighted = Weighted(u32, f64).init(&rand);

    const items = [_]u32{ 1, 2, 3, 4 };
    const weights = [_]f64{ 0.1, 0.5, 0.2, 0.2 };

    const val = weighted.sample(items[0..], weights[0..]);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Weighted UInts Slice" {
    const allocator = std.testing.allocator;

    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.Xoroshiro128.init(seed);
    var rand = prng.random();
    var weighted = Weighted(u32, f64).init(&rand);

    const items = [_]u32{ 1, 2, 3, 4 };
    const weights = [_]f64{ 0.1, 0.5, 0.2, 0.2 };

    const sample = try weighted.sampleSlice(
        100,
        items[0..],
        weights[0..],
        allocator,
    );
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Sample Weighted Uint Expectation" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.Xoroshiro128.init(seed);
    var rand = prng.random();
    var weighted = Weighted(u32, f64).init(&rand);

    const items = [_]u32{ 1, 2, 3, 4 };
    const weights = [_]f64{ 0.1, 0.5, 0.2, 0.2 };

    var expectation = [_]f64{ 0.0, 0.0, 0.0, 0.0 };

    for (0..10_000) |_| {
        const val = weighted.sample(items[0..], weights[0..]);
        const idx: usize = @intCast(val - 1);
        expectation[idx] += 1.0;
    }

    for (weights, expectation) |w, e| {
        std.debug.print("\nTruth: {}\tEstimated Exp.: {}\n", .{ w, e / 10_000.0 });
    }
}

test "Sample Weighted Struct" {
    const Pair = struct {
        v1: u32,
        v2: u32,
    };

    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.Xoroshiro128.init(seed);
    var rand = prng.random();
    var weighted = Weighted(Pair, f64).init(&rand);

    const items = [_]Pair{
        .{ .v1 = 20, .v2 = 40 },
        .{ .v1 = 10, .v2 = 20 },
        .{ .v1 = 30, .v2 = 60 },
        .{ .v1 = 80, .v2 = 160 },
    };
    const weights = [_]f64{ 0.2, 0.3, 0.4, 0.1 };

    const val = weighted.sample(items[0..], weights[0..]);
    std.debug.print("\n{any}\n", .{val});
}
