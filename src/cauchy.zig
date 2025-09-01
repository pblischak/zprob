const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const utils = @import("utils.zig");

pub const CauchyError = error{ScaleTooSmall};

/// Cauchy distribution with median parameter `x0` and scale parameter `gamma`.
///
/// [https://en.wikipedia.org/wiki/Cauchy_distribution](https://en.wikipedia.org/wiki/Cauchy_distribution)
pub fn Cauchy(comptime F: type) type {
    _ = utils.ensureFloatType(F);

    return struct {
        const Self = @This();

        pub fn sample(self: Self, x0: F, gamma: F, rand: *Random) CauchyError!F {
            _ = self;
            if (gamma <= 0) {
                return CauchyError.ScaleTooSmall;
            }
            var u: F = @floatCast(rand.float(f64));
            // u cannot be 0.5, so if by chance it is,
            // we need to draw again
            while (u == 0.5) {
                u = @floatCast(rand.float(f64));
            }

            return x0 + gamma * @tan(math.pi * (u - 0.5));
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            x0: F,
            gamma: F,
            rand: *Random,
            allocator: Allocator,
        ) (CauchyError || Allocator.Error)![]F {
            var res = try allocator.alloc(F, size);
            if (gamma <= 0) {
                return CauchyError.ScaleTooSmall;
            }
            for (0..size) |i| {
                res[i] = try self.sample(x0, gamma, rand);
            }
            return res;
        }

        pub fn pdf(self: Self, x: F, x0: F, gamma: F) CauchyError!F {
            _ = self;
            if (gamma <= 0) {
                return CauchyError.ScaleTooSmall;
            }
            return (1.0 / math.pi) * (gamma / (((x - x0) * (x - x0)) + (gamma * gamma)));
        }

        pub fn lnPdf(self: Self, x: F, x0: F, gamma: F) CauchyError!F {
            if (gamma <= 0) {
                return CauchyError.ScaleTooSmall;
            }
            return @log(try self.pdf(x, x0, gamma));
        }
    };
}

test "Cauchy gamma (scale) <= 0" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    const cauchy = Cauchy(f64){};

    const val1 = cauchy.sample(2.0, -1.0, &rand);
    try std.testing.expectError(error.ScaleTooSmall, val1);
    const val2 = cauchy.pdf(1.0, 2.0, -1.0);
    try std.testing.expectError(error.ScaleTooSmall, val2);
    const val3 = cauchy.lnPdf(1.0, 2.0, -1.0);
    try std.testing.expectError(error.ScaleTooSmall, val3);
}

test "Sample Cauchy" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    const cauchy = Cauchy(f64){};

    const val = try cauchy.sample(2.0, 1.0, &rand);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Cauchy Slice" {
    const allocator = std.testing.allocator;
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    const cauchy = Cauchy(f64){};

    const sample = try cauchy.sampleSlice(100, 2.0, 1.0, &rand, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Cauchy Median" {
    const allocator = std.testing.allocator;
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    const cauchy = Cauchy(f64){};

    const x0_vec = [_]f64{ -5, -2, 0, 2, 5 };
    const gamma_vec = [_]f64{ 1.0, 2.0, 3.0 };

    std.debug.print("\n", .{});
    for (x0_vec) |x0| {
        for (gamma_vec) |gamma| {
            var sample = try cauchy.sampleSlice(10_000, x0, gamma, &rand, allocator);
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

    const float_types = [_]type{ f32, f64 };

    std.debug.print("\n", .{});
    inline for (float_types) |f| {
        const cauchy = Cauchy(f){};
        const val = try cauchy.sample(10, 0.25, &rand);
        std.debug.print("Cauchy({any}):\t{}\n", .{ f, val });
    }
}
