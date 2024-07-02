const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const utils = @import("utils.zig");

/// Geometric distribution with parameter `p`. Records the number of trials needed to get the
///  first success.
///
/// [https://en.wikipedia.org/wiki/Geometric_distribution](https://en.wikipedia.org/wiki/Geometric_distribution)
pub fn Geometric(comptime I: type, comptime F: type) type {
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

        pub fn sample(self: Self, p: F) I {
            const u: F = @floatCast(self.rand.float(f64));
            return @as(I, @intFromFloat(@log(u) / @log(1.0 - p))) + 1;
        }

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

        pub fn pmf(self: Self, k: I, p: F) F {
            _ = self;
            return @as(F, math.pow(
                f64,
                @floatCast(1.0 - p),
                @as(f64, @floatFromInt(k)) - 1.0,
            )) * p;
        }

        pub fn lnPmf(self: Self, k: I, p: F) F {
            _ = self;
            return (@as(F, @floatFromInt(k)) - 1.0) * @log(1.0 - p) + @log(p);
        }
    };
}

test "Sample Geometric" {
    const seed: u64 = @intCast(std.time.milliTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var geometric = Geometric(u32, f64).init(&rand);
    const val = geometric.sample(0.2);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Geometric Slice" {
    const seed: u64 = @intCast(std.time.milliTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var geometric = Geometric(u32, f64).init(&rand);
    const allocator = std.testing.allocator;
    const sample = try geometric.sampleSlice(100, 0.2, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Geometric Mean" {
    const seed: u64 = @intCast(std.time.milliTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var geometric = Geometric(u32, f64).init(&rand);

    const p_vec = [_]f64{ 0.05, 0.1, 0.2, 0.4, 0.5, 0.6, 0.8, 0.9, 0.95 };

    std.debug.print("\n", .{});
    for (p_vec) |p| {
        var sum: f64 = 0.0;
        var samp: u32 = undefined;
        for (0..10_000) |_| {
            samp = geometric.sample(p);
            sum += @as(f64, @floatFromInt(samp));
        }
        const avg: f64 = sum / 10_000.0;
        // const mean: f64 = (1.0 - p) / p;
        const mean: f64 = (1.0) / p;
        // const variance: f64 = (1.0 - p) / (p * p);
        const variance: f64 = (1.0) / (p * p);
        std.debug.print(
            "Mean: {}\tAvg: {}\tStdDev: {}\n",
            .{ mean, avg, @sqrt(variance) },
        );
        try std.testing.expectApproxEqAbs(
            mean,
            avg,
            @sqrt(variance),
        );
    }
}

test "Geometric with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const int_types = [_]type{ u8, u16, u32, u64, u128, i8, i16, i32, i64, i128 };
    const float_types = [_]type{ f32, f64, f128 };

    std.debug.print("\n", .{});
    inline for (int_types) |i| {
        inline for (float_types) |f| {
            var geometric = Geometric(i, f).init(&rand);
            const val = geometric.sample(0.2);
            std.debug.print("Binomial({any}, {any}):\t{}\n", .{ i, f, val });
        }
    }
}

test "Geometric PMF" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var geometric = Geometric(u32, f64).init(&rand);
    const val = geometric.pmf(5, 0.4);
    const ln_val = geometric.lnPmf(5, 0.4);
    std.debug.print(
        "\nP(k = 5; p = 0.4) = {}\t{}\n",
        .{ val, @exp(ln_val) },
    );
}
