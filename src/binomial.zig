const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.Random;

const spec_fn = @import("special_functions.zig");
const utils = @import("utils.zig");

/// Binomial distribution with parameters `p` and `n`.
///
/// [https://en.wikipedia.org/wiki/Binomial_distribution](https://en.wikipedia.org/wiki/Binomial_distribution)
pub fn Binomial(comptime I: type, comptime F: type) type {
    _ = utils.ensureIntegerType(I);
    _ = utils.ensureFloatType(F);

    return struct {
        rand: *Random,
        const Self = @This();
        pub const Error = error{ KOutOfRange, ParamTooSmall, ParamTooBig };

        pub fn init(rand: *Random) Self {
            return Self{
                .rand = rand,
            };
        }

        /// Generate a single random sample from a binomial
        /// distribution whose number of trials is `n` and whose
        /// probability of success in each trial is `p`.
        ///
        /// Reference:
        ///
        ///   Voratas Kachitvichyanukul, Bruce Schmeiser,
        ///   Binomial Random Variate Generation,
        ///   Communications of the ACM,
        ///   Volume 31, Number 2, February 1988, pages 216-222.
        pub fn sample(self: Self, n: I, p: F) Error!I {
            if (p < 0.0) {
                return Error.ParamTooSmall;
            }
            if (p > 1.0) {
                return Error.ParamTooBig;
            }
            var al: F = 0.0;
            var alv: F = 0.0;
            var amaxp: F = 0.0;
            var c: F = 0.0;
            var f: F = 0.0;
            var f1: F = 0.0;
            var f2: F = 0.0;
            var ffm: F = 0.0;
            var fm: F = 0.0;
            var g: F = 0.0;
            var i: I = 0;
            var ix: I = 0;
            var ix1: I = 0;
            var k: I = 0;
            var m: I = 0;
            var mp: I = 0;
            var p0: F = 0.0;
            var p1: F = 0.0;
            var p2: F = 0.0;
            var p3: F = 0.0;
            var p4: F = 0.0;
            var q: F = 0.0;
            var qn: F = 0.0;
            var r: F = 0.0;
            var t: F = 0.0;
            var u: F = 0.0;
            var v: F = 0.0;
            var value: I = 0;
            var w: F = 0.0;
            var w2: F = 0.0;
            var x: F = 0.0;
            var x1: F = 0.0;
            var x2: F = 0.0;
            var xl: F = 0.0;
            var xll: F = 0.0;
            var xlr: F = 0.0;
            var xm: F = 0.0;
            var xnp: F = 0.0;
            var xnpq: F = 0.0;
            var xr: F = 0.0;
            var ynorm: F = 0.0;
            var z: F = 0.0;
            var z2: F = 0.0;

            const p_F: F = @floatCast(p);
            p0 = @min(p_F, 1.0 - p_F);
            q = 1.0 - p0;
            // xnp = @intToFloat(F, n) * p0;
            xnp = @as(F, @floatFromInt(n)) * p0;

            if (xnp < 30.0) {
                // qn = math.pow(F, q, @as(F, @floatFromInt(n)));
                qn = @floatCast(math.pow(
                    f64,
                    @floatCast(q),
                    @as(f64, @floatFromInt(n)),
                ));
                r = p0 / q;
                g = r * @as(F, @floatFromInt(n + 1));

                while (true) {
                    ix = 0;
                    f = qn;
                    // u = @as(F, self.rand.float(f64));
                    u = @floatCast(self.rand.float(f64));

                    while (true) {
                        if (u < f) {
                            if (0.5 < p_F) {
                                ix = n - ix;
                            }
                            value = ix;
                            return value;
                        }

                        if (110 < ix) {
                            break;
                        }
                        u = u - f;
                        ix = ix + 1;
                        f = f * (g / @as(F, @floatFromInt(ix)) - r);
                    }
                }
            }
            ffm = xnp + p0;
            m = @as(I, @intFromFloat(ffm));
            fm = @as(F, @floatFromInt(m));
            xnpq = xnp * q;
            p1 = @as(F, @floatFromInt(@as(I, @intFromFloat(2.195 * @sqrt(xnpq) - 4.6 * q)))) + 0.5;
            xm = fm + 0.5;
            xl = xm - p1;
            xr = xm + p1;
            c = 0.134 + 20.5 / (15.3 + fm);
            al = (ffm - xl) / (ffm - xl * p0);
            xll = al * (1.0 + 0.5 * al);
            al = (xr - ffm) / (xr * q);
            xlr = al * (1.0 + 0.5 * al);
            p2 = p1 * (1.0 + c + c);
            p3 = p2 + c / xll;
            p4 = p3 + c / xlr;
            //
            //  Generate a variate.
            //
            while (true) {
                // u = @as(F, self.rand.float(f64)) * p4;
                u = @floatCast(self.rand.float(f64));
                u *= p4;
                // v = @as(F, self.rand.float(f64));
                v = @floatCast(self.rand.float(f64));
                //
                //  Triangle
                //
                if (u < p1) {
                    ix = @as(I, @intFromFloat(xm - p1 * v + u));
                    if (0.5 < p_F) {
                        ix = n - ix;
                    }
                    value = ix;
                    return value;
                }
                //
                //  Parallelogram
                //
                if (u <= p2) {
                    x = xl + (u - p1) / c;
                    v = v * c + 1.0 - @abs(xm - x) / p1;

                    if (v <= 0.0 or 1.0 < v) {
                        continue;
                    }
                    ix = @as(I, @intFromFloat(x));
                } else if (u <= p3) {
                    ix = @as(I, @intFromFloat(xl + @log(v) / xll));
                    if (ix < 0) {
                        continue;
                    }
                    v = v * (u - p2) * xll;
                } else {
                    ix = @as(I, @intFromFloat(xr - @log(v) / xlr));
                    if (n < ix) {
                        continue;
                    }
                    v = v * (u - p3) * xlr;
                }
                // Required for safely handling signed and unsigned integer casting,
                // which throws a compile error because you cannot safely cast between,
                // e.g., u32 and i32.
                k = @as(
                    I,
                    @intFromFloat(@abs(@as(F, @floatFromInt(ix)) - @as(F, @floatFromInt(m)))),
                );

                if (k <= 20 or xnpq / 2.0 - 1.0 <= @as(F, @floatFromInt(k))) {
                    f = 1.0;
                    r = p0 / q;
                    g = @as(F, @floatFromInt(n + 1)) * r;

                    if (m < ix) {
                        mp = m + 1;
                        i = mp;
                        while (i < ix) : (i += 1) {
                            f = f * (g / @as(F, @floatFromInt(i)) - r);
                        }
                    } else if (ix < m) {
                        ix1 = ix + 1;
                        i = ix1;
                        while (i <= m) : (i += 1) {
                            f = f / (g / @as(F, @floatFromInt(i)) - r);
                        }
                    }

                    if (v <= f) {
                        if (0.5 < p_F) {
                            ix = n - ix;
                        }
                        value = ix;
                        return value;
                    }
                } else {
                    const k_f = @as(F, @floatFromInt(k));
                    amaxp = (k_f / xnpq) * ((k_f * (k_f / 3.0 + 0.625) + 0.1666666666666) / xnpq + 0.5);
                    ynorm = -(k_f * k_f) / (2.0 * xnpq);
                    alv = @log(v);

                    if (alv < ynorm - amaxp) {
                        if (0.5 < p_F) {
                            ix = n - ix;
                        }
                        value = ix;
                        return value;
                    }

                    if (ynorm + amaxp < alv) {
                        continue;
                    }

                    x1 = @as(F, @floatFromInt(ix + 1));
                    f1 = fm + 1.0;
                    z = @as(F, @floatFromInt(n + 1)) - fm;
                    w = @as(F, @floatFromInt(n - ix + 1));
                    z2 = z * z;
                    x2 = x1 * x1;
                    f2 = f1 * f1;
                    w2 = w * w;

                    // zig fmt: off
                    const n_f = @as(F, @floatFromInt(n));
                    const m_f = @as(F, @floatFromInt(m));
                    t = xm * @log(f1 / x1) + (n_f - m_f + 0.5) * @log(z / w)
                        + @as(F, @floatFromInt(ix - m)) * @log(w * p0 / (x1 * q))
                        + (13860.0 - (462.0 - (132.0 - (99.0 - 140.0 / f2) / f2) / f2) / f2) / f1 / 166320.0
                        + (13860.0 - (462.0 - (132.0 - (99.0 - 140.0 / z2) / z2) / z2) / z2) / z / 166320.0
                        + (13860.0 - (462.0 - (132.0 - (99.0 - 140.0 / x2) / x2) / x2) / x2) / x1 / 166320.0 
                        + (13860.0 - (462.0 - (132.0 - (99.0 - 140.0 / w2) / w2) / w2) / w2) / w / 166320.0;
                    // zig fmt: on

                    if (alv <= t) {
                        if (0.5 < p_F) {
                            ix = n - ix;
                        }
                        value = ix;
                        return value;
                    }
                }
            }
            return value;
        }

        pub fn sampleSlice(
            self: Self,
            size: usize,
            n: I,
            p: F,
            allocator: Allocator,
        ) (Error || Allocator.Error)![]I {
            var res = try allocator.alloc(I, size);
            for (0..size) |i| {
                res[i] = try self.sample(n, p);
            }
            return res;
        }

        pub fn pmf(self: *Self, k: I, n: I, p: F) !F {
            if (p < 0.0) {
                return Error.ParamTooSmall;
            }
            if (p > 1.0) {
                return Error.ParamTooBig;
            }
            if (k > n or k < 0) {
                return Error.KOutOfRange;
            }
            const val = self.lnPmf(k, n, p) catch |err| {
                return err;
            };
            return @exp(val);
        }

        pub fn lnPmf(self: *Self, k: I, n: I, p: F) !F {
            _ = self;
            if (p < 0.0) {
                return Error.ParamTooSmall;
            }
            if (p > 1.0) {
                return Error.ParamTooBig;
            }
            if (k > n or k < 0) {
                return Error.KOutOfRange;
            }
            const ln_coeff = try spec_fn.lnNChooseK(I, F, n, k);
            // zig fmt: off
            return ln_coeff
                + @as(F, @floatFromInt(k)) * @log(p)
                + @as(F, @floatFromInt(n - k)) * @log(1.0 - p);
            // zig fmt: on
        }
    };
}

test "Binomial `p` < 0" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var binomial = Binomial(u32, f64).init(&rand);

    const val = binomial.sample(10, -0.2);
    try std.testing.expectError(error.ParamTooSmall, val);

    const val2 = binomial.pmf(8, 10, -0.2);
    try std.testing.expectError(error.ParamTooSmall, val2);

    const val3 = binomial.lnPmf(8, 10, -0.2);
    try std.testing.expectError(error.ParamTooSmall, val3);
}

test "Binomial `p` > 1" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var binomial = Binomial(u32, f64).init(&rand);

    const val = binomial.sample(10, 1.2);
    try std.testing.expectError(error.ParamTooBig, val);

    const val2 = binomial.pmf(8, 10, 1.2);
    try std.testing.expectError(error.ParamTooBig, val2);

    const val3 = binomial.lnPmf(8, 10, 1.2);
    try std.testing.expectError(error.ParamTooBig, val3);
}
test "Binomial `k` out of range" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var binomial = Binomial(i32, f64).init(&rand);

    const val1 = binomial.pmf(10, 8, 0.1);
    try std.testing.expectError(error.KOutOfRange, val1);
    const val2 = binomial.pmf(-2, 8, 0.1);
    try std.testing.expectError(error.KOutOfRange, val2);
}

test "Sample Binomial" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    var binomial = Binomial(u32, f64).init(&rand);
    const val = try binomial.sample(10, 0.2);
    std.debug.print("\n{}\n", .{val});
}

test "Sample Binomial Slice" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    const allocator = std.testing.allocator;

    var binomial = Binomial(u32, f64).init(&rand);
    const sample = try binomial.sampleSlice(100, 10, 0.2, allocator);
    defer allocator.free(sample);
    std.debug.print("\n{any}\n", .{sample});
}

test "Binomial Mean" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();
    var binomial = Binomial(u32, f64).init(&rand);

    const n_vec = [_]u32{ 2, 5, 10, 25, 50 };
    const p_vec = [_]f64{ 0.05, 0.1, 0.2, 0.4, 0.5, 0.6, 0.8, 0.9, 0.95 };

    std.debug.print("\n", .{});
    for (n_vec) |n| {
        for (p_vec) |p| {
            var samp: f64 = undefined;
            var sum: f64 = 0.0;
            for (0..10_000) |_| {
                samp = @as(f64, @floatFromInt(try binomial.sample(n, p)));
                sum += samp;
            }

            const mean: f64 = @as(f64, @floatFromInt(n)) * p;
            const avg: f64 = sum / 10_000;
            const variance: f64 = @as(f64, @floatFromInt(n)) * p * (1.0 - p);
            std.debug.print(
                "Mean: {}\tAvg: {}\tStdDev {}\n",
                .{ mean, avg, @sqrt(variance) },
            );
            try std.testing.expectApproxEqAbs(mean, avg, @sqrt(variance));
        }
    }
}

test "Binomial with Different Types" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const int_types = [_]type{ u8, u16, u32, u64, u128, i8, i16, i32, i64, i128 };
    const float_types = [_]type{ f32, f64 };

    std.debug.print("\n", .{});
    inline for (int_types) |i| {
        inline for (float_types) |f| {
            var binomial = Binomial(i, f).init(&rand);
            const val = try binomial.sample(10, 0.25);
            std.debug.print("Binomial({any}, {any}):\t{}\n", .{ i, f, val });
            const pmf = try binomial.pmf(4, 10, 0.25);
            std.debug.print("BinomialPmf({any}, {any}):\t{}\n", .{ i, f, pmf });
            const ln_pmf = try binomial.lnPmf(4, 10, 0.25);
            std.debug.print("BinomialLnPmf({any}, {any}):\t{}\n", .{ i, f, ln_pmf });
        }
    }
}
