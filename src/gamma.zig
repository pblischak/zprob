const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const utils = @import("utils.zig");

pub const GammaError = error{
    ShapeInvalid,
    ScaleInvalid,
    ParamsInfinite,
};

/// Gamma distribution with parameters `shape` and `scale` (`1 / rate`).
///
/// [https://en.wikipedia.org/wiki/Gamma_distribution](https://en.wikipedia.org/wiki/Gamma_distribution)
pub fn Gamma(comptime F: type) type {
    _ = utils.ensureFloatType(F);

    return struct {
        rand: *Random,

        const Self = @This();

        pub fn init(rand: *Random) Self {
            return Self{
                .rand = rand,
            };
        }

        fn check(shape: F, scale: F) GammaError!void {
            if (math.isNan(shape) or shape <= 0.0) {
                return GammaError.ShapeInvalid;
            }
            if (math.isNan(scale) or scale <= 0.0) {
                return GammaError.ScaleInvalid;
            }
            if (math.isInf(shape) and math.isInf(scale)) {
                return GammaError.ParamsInfinite;
            }
        }

        // GEORGE MARSAGLIA and WAI WAN TSANG. A Simple Method for Generating Gamma Variables.
        // ACM Transactions on Mathematical Software, Vol. 26, September 2000, Pages 363–37.
        pub fn sample(self: Self, shape: F, scale: F) GammaError!F {
            try check(shape, scale);

            if (shape < 1) {
                const u: F = @floatCast(self.rand.float(f64));
                return try self.sample(
                    1.0 + shape,
                    scale,
                ) * @as(F, @floatCast(math.pow(
                    f64,
                    @floatCast(u),
                    @floatCast(1.0 / shape),
                )));
            }

            var x: F = undefined;
            var v: F = undefined;
            var u: F = undefined;
            const d: F = shape - (1.0 / 3.0);
            const c: F = (1.0 / 3.0) / @sqrt(d);

            while (true) {
                x = @floatCast(self.rand.floatNorm(f64));
                v = 1.0 + c * x;
                while (v <= 0) {
                    x = @floatCast(self.rand.floatNorm(f64));
                    v = 1.0 + c * x;
                }

                v = v * v * v;
                u = @floatCast(self.rand.float(f64));

                if (u < 1.0 - (0.0331 * x * x * x * x)) {
                    break;
                }

                if (@log(u) < (0.5 * x * x) + d * (1.0 - v + @log(v))) {
                    break;
                }
            }

            return scale * d * v;
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            shape: F,
            scale: F,
            allocator: Allocator,
        ) (GammaError || Allocator.Error)![]F {
            var res = try allocator.alloc(F, size);
            for (0..size) |i| {
                res[i] = try self.sample(shape, scale);
            }
            return res;
        }

        pub fn pdf(self: Self, x: F, shape: F, scale: F) !F {
            _ = self;
            if (x < 0) {
                return 0.0;
            } else if (x == 0) {
                if (shape == 1) {
                    return 1.0 / scale;
                } else {
                    return 0;
                }
            } else if (shape == 1) {
                return @exp(-x / scale) / scale;
            } else {
                const ln_gamma_val: F = math.lgamma(F, shape);
                return @exp((shape - 1) * @log(x / scale) - x / scale - ln_gamma_val) / scale;
            }
        }

        pub fn lnPdf(self: Self, x: F, shape: F, scale: F) !F {
            if (x < 0) {
                @panic("Parameter `x` must be greater than 0.");
            }
            const val = try self.pdf(x, shape, scale);
            return @log(val);
        }
    };
}

test "Sample Gamma" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var gamma = Gamma(f64).init(&rand);
    const val = try gamma.sample(2.0, 5.0);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Gamma Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var gamma = Gamma(f64).init(&rand);
    const allocator = std.testing.allocator;
    const sample = try gamma.sampleSlice(100, 2.0, 5.0, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Gamma Mean" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var gamma = Gamma(f64).init(&rand);

    const shape_vec = [_]f64{ 0.1, 0.5, 2.0, 5.0, 10.0, 20.0, 50.0 };
    const scale_vec = [_]f64{ 0.1, 0.5, 2.0, 5.0, 10.0, 20.0, 50.0 };

    std.debug.print("\n", .{});
    for (shape_vec) |shape| {
        for (scale_vec) |scale| {
            var sum: f64 = 0.0;
            for (0..10_000) |_| {
                sum += try gamma.sample(shape, scale);
            }
            const mean = shape * scale;
            const avg = sum / 10_000.0;
            const variance = shape * scale * scale;
            std.debug.print(
                "Mean: {}\tAvg: {}\tStdDev: {}\n",
                .{ mean, avg, @sqrt(variance) },
            );
            try std.testing.expectApproxEqAbs(mean, avg, @sqrt(variance));
        }
    }
}

test "Gamma with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.Xoroshiro128.init(seed);
    var rand = prng.random();

    const float_types = [_]type{ f32, f64 };

    std.debug.print("\n", .{});
    inline for (float_types) |f| {
        var gamma = Gamma(f).init(&rand);
        const val = try gamma.sample(5.0, 2.0);
        std.debug.print("Gamma({any}):\t{}\n", .{ f, val });
    }
}
