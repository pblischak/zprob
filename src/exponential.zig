const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const utils = @import("utils.zig");

pub const ExponentialError = error{LambdaInvalid};

/// Exponential distribution with parameter `lambda`.
///
/// [https://en.wikipedia.org/wiki/Exponential_distribution](https://en.wikipedia.org/wiki/Exponential_distribution)
pub fn Exponential(comptime F: type) type {
    _ = utils.ensureFloatType(F);

    return struct {
        rand: *Random,

        const Self = @This();

        pub fn init(rand: *Random) Self {
            return Self{
                .rand = rand,
            };
        }

        pub fn sample(self: Self, lambda: F) ExponentialError!F {
            if (math.isNan(lambda) or lambda <= 0) {
                return ExponentialError.LambdaInvalid;
            }
            const u: F = @floatCast(self.rand.float(f64));
            const value = -@log(1.0 - u) / lambda;
            return value;
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            lambda: F,
            allocator: Allocator,
        ) (ExponentialError || Allocator.Error)![]F {
            var res = try allocator.alloc(F, size);
            for (0..size) |i| {
                res[i] = try self.sample(lambda);
            }
            return res;
        }

        pub fn pdf(self: Self, x: F, lambda: F) ExponentialError!F {
            _ = self;
            if (math.isNan(lambda) or lambda <= 0) {
                return ExponentialError.LambdaInvalid;
            }
            if (x < 0) {
                return 0.0;
            }
            const value = lambda * @exp(-lambda * x);
            return value;
        }

        pub fn lnPdf(self: Self, x: F, lambda: F) ExponentialError!F {
            if (math.isNan(lambda) or lambda <= 0) {
                return ExponentialError.LambdaInvalid;
            }
            if (x < 0) {
                @panic("Cannot evaluate x less than 0.");
            }
            const value = try self.pdf(x, lambda);
            return @log(value);
        }
    };
}

test "Sample Exponential" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var exponential = Exponential(f64).init(&rand);
    const val = try exponential.sample(5.0);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Exponential Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var exponential = Exponential(f64).init(&rand);
    const allocator = std.testing.allocator;
    const sample = try exponential.sampleSlice(100, 5.0, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Exponential Mean" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var exponential = Exponential(f64).init(&rand);

    const lambda_vec = [_]f64{ 0.1, 0.5, 2.0, 5.0, 10.0, 20.0, 50.0 };

    for (lambda_vec) |lambda| {
        var sum: f64 = 0.0;
        for (0..10_000) |_| {
            sum += try exponential.sample(lambda);
        }
        const mean = 1.0 / lambda;
        const avg = sum / 10_000.0;
        const variance = 1.0 / (lambda * lambda);
        std.debug.print(
            "Mean: {}\tAvg: {}\tStdDev: {}\n",
            .{ mean, avg, @sqrt(variance) },
        );
        try std.testing.expectApproxEqAbs(mean, avg, @sqrt(variance));
    }
}

test "Exponential with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    const float_types = [_]type{ f32, f64 };

    inline for (float_types) |f| {
        var exponential = Exponential(f).init(&rand);
        const val = try exponential.sample(5.0);
        std.debug.print("Exponential({any}):\t{}\n", .{ f, val });
    }
}
