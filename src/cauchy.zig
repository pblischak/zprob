const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const utils = @import("utils.zig");

/// Cauchy distribution with median parameter `x0` and scale parameter `gamma`.
///
/// [https://en.wikipedia.org/wiki/Cauchy_distribution](https://en.wikipedia.org/wiki/Cauchy_distribution)
pub fn Cauchy(comptime F: type) type {
    _ = utils.ensureFloatType(F);

    return struct {
        rand: *Random,

        const Self = @This();
        const Error = error{ScaleTooSmall};

        pub fn init(rand: *Random) Self {
            return Self{
                .rand = rand,
            };
        }

        pub fn sample(self: Self, x0: F, gamma: F) Error!F {
            if (gamma <= 0) {
                return Error.ScaleTooSmall;
            }
            var u: F = @floatCast(self.rand.float(f64));
            // u cannot be 0.5, so if by chance it is,
            // we need to draw again
            while (u == 0.5) {
                u = @floatCast(self.rand.float(f64));
            }

            return x0 + gamma * @tan(math.pi * (u - 0.5));
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            x0: F,
            gamma: F,
            allocator: Allocator,
        ) (Error || Allocator.Error)![]F {
            var res = try allocator.alloc(F, size);
            if (gamma <= 0) {
                return Error.ScaleTooSmall;
            }
            for (0..size) |i| {
                res[i] = try self.sample(x0, gamma);
            }
            return res;
        }

        pub fn pdf(self: Self, x: F, x0: F, gamma: F) Error!F {
            _ = self;
            if (gamma <= 0) {
                return Error.ScaleTooSmall;
            }
            return (1.0 / math.pi) * (gamma / (((x - x0) * (x - x0)) + (gamma * gamma)));
        }

        pub fn lnPdf(self: Self, x: F, x0: F, gamma: F) Error!F {
            if (gamma <= 0) {
                return Error.ScaleTooSmall;
            }
            return @log(try self.pdf(x, x0, gamma));
        }
    };
}

test "Sample Cauchy" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var cauchy = Cauchy(f64).init(&rand);

    const val = cauchy.sample(2.0, 1.0);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Cauchy Slice" {
    const allocator = std.testing.allocator;
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var cauchy = Cauchy(f64).init(&rand);

    const sample = try cauchy.sampleSlice(100, 2.0, 1.0, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Cauchy Median" {
    const allocator = std.testing.allocator;
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var cauchy = Cauchy(f64).init(&rand);

    const x0_vec = [_]f64{ -5, -2, 0, 2, 5 };
    const gamma_vec = [_]f64{ 1.0, 2.0, 3.0 };

    std.debug.print("\n", .{});
    for (x0_vec) |x0| {
        for (gamma_vec) |gamma| {
            var sample = try cauchy.sampleSlice(10_000, x0, gamma, allocator);
            defer allocator.free(sample);
            std.sort.block(f64, sample[0..], {}, std.sort.asc(f64));
            const median = (sample[4999] + sample[5000]) / 2.0;
            std.debug.print(
                "x0: {}\tMedian: {}\n",
                .{ x0, median },
            );
            try std.testing.expectApproxEqAbs(x0, median, 0.4);
        }
    }
}

test "Cauchy with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const float_types = [_]type{ f32, f64, f128 };

    std.debug.print("\n", .{});
    inline for (float_types) |f| {
        var cauchy = Cauchy(f).init(&rand);
        const val = cauchy.sample(10, 0.25);
        std.debug.print("Cauchy({any}):\t{}\n", .{ f, val });
    }
}
