//! Binomial distribution with parameters `p` and `n`.

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

const spec_fn = @import("special_functions.zig");

/// Generate a single random sample from a binomial
/// distribution whose number of trials is `n` and whose
/// probability of an event in each trial is `p`.
///
/// Reference:
///
///   Voratas Kachitvichyanukul, Bruce Schmeiser,
///   Binomial Random Variate Generation,
///   Communications of the ACM,
///   Volume 31, Number 2, February 1988, pages 216-222.
pub fn binomialSample(comptime I: type, comptime F: type, n: I, p: F, rng: *Random) I {
    var al: f64 = 0.0;
    var alv: f64 = 0.0;
    var amaxp: f64 = 0.0;
    var c: f64 = 0.0;
    var f: f64 = 0.0;
    var f1: f64 = 0.0;
    var f2: f64 = 0.0;
    var ffm: f64 = 0.0;
    var fm: f64 = 0.0;
    var g: f64 = 0.0;
    var i: i32 = 0;
    var ix: i32 = 0;
    var ix1: i32 = 0;
    var k: i32 = 0;
    var m: i32 = 0;
    var mp: i32 = 0;
    var p0: f64 = 0.0;
    var p1: f64 = 0.0;
    var p2: f64 = 0.0;
    var p3: f64 = 0.0;
    var p4: f64 = 0.0;
    var q: f64 = 0.0;
    var qn: f64 = 0.0;
    var r: f64 = 0.0;
    var t: f64 = 0.0;
    var u: f64 = 0.0;
    var v: f64 = 0.0;
    var value: i32 = 0;
    var w: f64 = 0.0;
    var w2: f64 = 0.0;
    var x: f64 = 0.0;
    var x1: f64 = 0.0;
    var x2: f64 = 0.0;
    var xl: f64 = 0.0;
    var xll: f64 = 0.0;
    var xlr: f64 = 0.0;
    var xm: f64 = 0.0;
    var xnp: f64 = 0.0;
    var xnpq: f64 = 0.0;
    var xr: f64 = 0.0;
    var ynorm: f64 = 0.0;
    var z: f64 = 0.0;
    var z2: f64 = 0.0;

    const p_f64 = @floatCast(f64, p);
    p0 = @min(p_f64, 1.0 - p_f64);
    q = 1.0 - p0;
    xnp = @intToFloat(f64, n) * p0;

    if (xnp < 30.0) {
        qn = math.pow(f64, q, @intToFloat(f64, n));
        r = p0 / q;
        g = r * @intToFloat(f64, n + 1);

        while (true) {
            ix = 0;
            f = qn;
            u = rng.float(f64);

            while (true) {
                if (u < f) {
                    if (0.5 < p_f64) {
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
                f = f * (g / @intToFloat(f64, ix) - r);
            }
        }
    }
    ffm = xnp + p0;
    m = @floatToInt(i32, ffm);
    fm = @intToFloat(f64, m);
    xnpq = xnp * q;
    p1 = @intToFloat(f64, @floatToInt(i32, (2.195 * @sqrt(xnpq) - 4.6 * q))) + 0.5;
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
        u = rng.float(f64) * p4;
        v = rng.float(f64);
        //
        //  Triangle
        //
        if (u < p1) {
            ix = @floatToInt(i32, xm - p1 * v + u);
            if (0.5 < p_f64) {
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
            v = v * c + 1.0 - math.fabs(xm - x) / p1;

            if (v <= 0.0 or 1.0 < v) {
                continue;
            }
            ix = @floatToInt(i32, x);
        } else if (u <= p3) {
            ix = @floatToInt(i32, xl + @log(v) / xll);
            if (ix < 0) {
                continue;
            }
            v = v * (u - p2) * xll;
        } else {
            ix = @floatToInt(i32, xr - @log(v) / xlr);
            if (n < ix) {
                continue;
            }
            v = v * (u - p3) * xlr;
        }
        k = math.absInt(ix - m) catch blk: {
            // zig fmt: off
            break :blk @floatToInt(
                i32,
                @fabs(@intToFloat(f64, ix)
                    - @intToFloat(f64, m))
            );
            // zig fmt: on
        };

        if (k <= 20 or xnpq / 2.0 - 1.0 <= @intToFloat(f64, k)) {
            f = 1.0;
            r = p0 / q;
            g = @intToFloat(f64, n + 1) * r;

            if (m < ix) {
                mp = m + 1;
                i = mp;
                while (i < ix) : (i += 1) {
                    f = f * (g / @intToFloat(f64, i) - r);
                }
            } else if (ix < m) {
                ix1 = ix + 1;
                i = ix1;
                while (i <= m) : (i += 1) {
                    f = f / (g / @intToFloat(f64, i) - r);
                }
            }

            if (v <= f) {
                if (0.5 < p_f64) {
                    ix = n - ix;
                }
                value = ix;
                return value;
            }
        } else {
            const k_f = @intToFloat(f64, k);
            amaxp = (k_f / xnpq) * ((k_f * (k_f / 3.0 + 0.625) + 0.1666666666666) / xnpq + 0.5);
            ynorm = -(k_f * k_f) / (2.0 * xnpq);
            alv = @log(v);

            if (alv < ynorm - amaxp) {
                if (0.5 < p_f64) {
                    ix = n - ix;
                }
                value = ix;
                return value;
            }

            if (ynorm + amaxp < alv) {
                continue;
            }

            x1 = @intToFloat(f64, ix + 1);
            f1 = fm + 1.0;
            z = @intToFloat(f64, n + 1) - fm;
            w = @intToFloat(f64, n - ix + 1);
            z2 = z * z;
            x2 = x1 * x1;
            f2 = f1 * f1;
            w2 = w * w;

            // zig fmt: off
            const n_f = @intToFloat(f64, n);
            const m_f = @intToFloat(f64, m);
            t = xm * @log(f1 / x1) + (n_f - m_f + 0.5) * @log(z / w)
                + @intToFloat(f64, ix - m) * @log(w * p0 / (x1 * q))
                + (13860.0 - (462.0 - (132.0 - (99.0 - 140.0 / f2) / f2) / f2) / f2) / f1 / 166320.0
                + (13860.0 - (462.0 - (132.0 - (99.0 - 140.0 / z2) / z2) / z2) / z2) / z / 166320.0
                + (13860.0 - (462.0 - (132.0 - (99.0 - 140.0 / x2) / x2) / x2) / x2) / x1 / 166320.0 
                + (13860.0 - (462.0 - (132.0 - (99.0 - 140.0 / w2) / w2) / w2) / w2) / w / 166320.0;
            // zig fmt: on

            if (alv <= t) {
                if (0.5 < p_f64) {
                    ix = n - ix;
                }
                value = ix;
                return value;
            }
        }
    }
    switch (I) {
        i32 => return value,
        i16 => return @intCast(i16, value),
        i8 => return @intCast(i8, value),
        u32 => return @intCast(u32, value),
        u16 => return @intCast(u16, value),
        u8 => return @intCast(u8, value),
    }
}

pub fn binomialPmf(comptime I: type, comptime F: type, k: I, n: I, p: F) F {
    if (k > n or k <= 0) {
        @panic("");
    }
    const coeff = try spec_fn.nChooseK(I, n, k);
    // zig fmt: off
    return @intToFloat(F, coeff)
        * math.pow(F, p, @intToFloat(F, k))
        * math.pow(F, 1.0 - p, @intToFloat(F, n - k));
    // zig fmt: on
}

pub fn binomialLnPmf(comptime I: type, comptime F: type, k: I, n: I, p: F) F {
    if (k > n or k <= 0) {
        @panic("");
    }
    const ln_coeff = try spec_fn.lnNChooseK(I, F, n, k);
    // zig fmt: off
    return ln_coeff
        + @intToFloat(F, k) * @log(p)
        + @intToFloat(F, n - k) * @log(1.0 - p);
    // zig fmt: on
}
