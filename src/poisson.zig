const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const spec_fn = @import("special_functions.zig");
const utils = @import("utils.zig");

/// Poisson distribution with parameter `lambda`.
///
/// [https://en.wikipedia.org/wiki/Poisson_distribution](https://en.wikipedia.org/wiki/Poisson_distribution)
pub fn Poisson(comptime I: type, comptime F: type) type {
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

        pub fn sample(self: Self, lambda: F) I {
            if (lambda < 17.0) {
                if (lambda < 1.0e-6) {
                    if (lambda == 0.0) {
                        return 0;
                    }

                    if (lambda < 0.0) {
                        @panic("Parameter lambda cannot be negative...");
                    }

                    return self.low(lambda);
                } else {
                    return self.inversion(lambda);
                }
            } else {
                if (lambda > 2.0e9) {
                    @panic("Parameter lambda too large...");
                }
                return self.ratioUniforms(lambda);
            }
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            lambda: F,
            allocator: Allocator,
        ) ![]I {
            var res = try allocator.alloc(I, size);
            for (0..size) |i| {
                res[i] = self.sample(lambda);
            }
            return res;
        }

        fn low(self: Self, lambda: F) I {
            const d: F = @sqrt(lambda);
            if (@as(F, @floatCast(self.rand.float(f64))) >= d) {
                return 0;
            }

            const r: F = @as(F, @floatCast(self.rand.float(f64))) * d;
            if (r > lambda * (1.0 - lambda)) {
                return 0;
            }
            if (r > 0.5 * lambda * lambda * (1.0 - lambda)) {
                return 1;
            }

            return 2;
        }

        fn inversion(self: Self, lambda: F) I {
            const bound: I = 127;
            const p_f0 = @exp(-lambda);
            var x: I = undefined;
            var r: F = undefined;
            var f: F = p_f0;

            while (true) {
                r = @floatCast(self.rand.float(f64));
                x = 0;
                f = p_f0;

                // Run first iteration since there is no do-while
                r -= f;
                if (r <= 0.0) {
                    return x;
                }
                x += 1;
                f *= lambda;
                r *= @as(F, @floatFromInt(x));

                while (x <= bound) {
                    r -= f;
                    if (r <= 0.0) {
                        return x;
                    }
                    x += 1;
                    f *= lambda;
                    r *= @as(F, @floatFromInt(x));
                }
            }
        }

        fn ratioUniforms(self: Self, lambda: F) I {
            var u: F = undefined;
            var lf: F = undefined;
            var x: F = undefined;
            var k: I = undefined;

            const p_a = lambda + 0.5;
            const mode = @as(I, @intFromFloat(lambda));
            const p_g = @log(lambda);
            const p_q = @as(F, @floatFromInt(mode)) * p_g - spec_fn.lnFactorial(I, F, mode);
            const p_h = @sqrt(2.943035529371538573 * (lambda + 0.5)) + 0.8989161620588987408;
            const p_bound = @as(I, @intFromFloat(p_a + 6.0 * p_h));

            while (true) {
                u = @floatCast(self.rand.float(f64));
                if (u == 0) {
                    continue;
                }

                x = p_a + p_h * (@as(F, @floatCast(self.rand.float(f64))) - 0.5) / u;
                if (x < 0.0 or x >= @as(F, @floatFromInt(p_bound))) {
                    continue;
                }

                k = @as(I, @intFromFloat(x));
                lf = @as(F, @floatFromInt(k)) * p_g - spec_fn.lnFactorial(I, F, k) - p_q;
                if (lf >= u * (4.0 - u) - 3.0) {
                    break;
                }
                if (u * (u - lf) > 1.0) {
                    continue;
                }
                if (2.0 * @log(u) <= lf) {
                    break;
                }
            }
            return k;
        }

        pub fn pmf(self: Self, k: I, lambda: F) F {
            return @exp(self.lnPmf(k, lambda));
        }

        pub fn lnPmf(self: Self, k: I, lambda: F) F {
            _ = self;
            return @as(
                F,
                @floatFromInt(k),
            ) * @log(lambda) - lambda + spec_fn.lnFactorial(I, F, k);
        }
    };
}

test "Sample Poisson" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var poisson = Poisson(u32, f64).init(&rand);
    const val = poisson.sample(20.0);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Poisson Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var poisson = Poisson(u32, f64).init(&rand);
    const allocator = std.testing.allocator;
    const sample = try poisson.sampleSlice(100, 20.0, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Poisson Mean" {
    const seed: u64 = @intCast(std.time.milliTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var poisson = Poisson(u32, f64).init(&rand);

    const lambda_vec = [_]f64{ 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0 };

    std.debug.print("\n", .{});
    for (lambda_vec) |lambda| {
        var sum: f64 = 0.0;
        for (0..10_000) |_| {
            const samp = poisson.sample(lambda);
            sum += @as(f64, @floatFromInt(samp));
        }
        const avg: f64 = sum / 10_000.0;
        std.debug.print("Mean: {}\tAvg: {}\tStdDev: {}\n", .{ lambda, avg, @sqrt(lambda) });
        try std.testing.expectApproxEqAbs(lambda, avg, @sqrt(lambda));
    }
}

test "Poisson with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const int_types = [_]type{ u8, u16, u32, u64, u128, i8, i16, i32, i64, i128 };
    const float_types = [_]type{ f32, f64, f128 };

    std.debug.print("\n", .{});
    inline for (int_types) |i| {
        inline for (float_types) |f| {
            var poisson = Poisson(i, f).init(&rand);
            const val = poisson.sample(20.0);
            std.debug.print(
                "Poisson({any}, {any}): {}\n",
                .{ i, f, val },
            );
        }
    }
}
