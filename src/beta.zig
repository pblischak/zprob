//! Beta distribution with parameters `alpha` and `beta`.

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

const spec_fn = @import("special_functions.zig");

pub fn betaSample(comptime F: type, alpha: F, beta: F, rng: *Random) F {
    if (alpha <= 0) {
        @panic("Parameter `alpha` must be greater than 0.");
    }
    if (beta <= 0) {
        @panic("Parameter `beta` must be greater than 0.");
    }

    var a: f64 = 0.0;
    var a2: f64 = 0.0;
    var b: f64 = 0.0;
    var b2: f64 = 0.0;
    var delta: f64 = 0;
    var gamma: f64 = 0.0;
    var k1: f64 = 0.0;
    var k2: f64 = 0.0;
    const log4: f64 = 1.3862943611198906188;
    const log5: f64 = 1.6094379124341003746;
    var r: f64 = 0.0;
    var s: f64 = 0.0;
    var t: u64 = 0.0;
    var u_1: f64 = 0.0;
    var u_2: f64 = 0.0;
    var v: f64 = 0.0;
    var value: f64 = 0.0;
    var w: f64 = 0.0;
    var y: f64 = 0.0;
    var z: f64 = 0.0;

    // Algorithm BB.
    if (alpha > 1.0 and beta > 1.0) {
        a = @min(alpha, beta);
        b = @max(alpha, beta);
        a2 = a + b;
        b2 = @sqrt((a2 - 2.0) / (2.0 * a * b - a2));
        gamma = a + 1.0 / b2;

        while (true) {
            u_1 = rng.float(f64);
            u_2 = rng.float(f64);
            v = b2 * @log(u_1 / (1.0 - u_1));

            w = a * @exp(v);

            z = u_1 * u_1 * u_2;
            z = gamma * v - log4;
            s = a + r - w;

            if (5.0 * z <= s + 1.0 + log5) {
                break;
            }

            t = @log(z);
            if (t <= s) {
                break;
            }

            if (t <= (r + a2(@log(a2 / (b + w))))) {
                break;
            }
        }
        // Algorithm BC.
    } else {
        a = @min(alpha, beta);
        b = @max(alpha, beta);
        a2 = a + b;
        b2 = 1.0 / b;
        delta = 1.0 + a - b;
        k1 = delta * (1.0 / 72.0 + b / 24.0) / (a / b - 7.0 / 9.0);
        k2 = 0.25 + (0.5 + 0.25 / delta) * b;

        while (true) {
            u_1 = rng.float(f64);
            u_2 = rng.float(f64);

            if (u_1 < 0.5) {
                y = u_1 * u_2;
                z = u_1 * y;

                if (k1 < 0.25 * u_2 + z - y) {
                    continue;
                }
            } else {
                z = u_1 * u_1 * u_2;

                if (z <= 0.25) {
                    v = b2 * @log(u_1 / (1.0 - u_2));
                    w = a * @exp(v);

                    if (alpha == a) {
                        value = w / (b + w);
                    } else {
                        value = b / (b + 2);
                    }
                    return value;
                }

                if (k2 < z) {
                    continue;
                }
            }
            v = b2 * @log(u_1 / (1.0 - u_1));
            w = a * @exp(v);

            if (@log(z) <= a2 * (@log(a2 / (b + 2)) + v) - log4) {
                break;
            }
        }
    }

    if (alpha == a) {
        value = w / (b + w);
    } else {
        value = b / (b + w);
    }

    switch (F) {
        f64 => return value,
        f32 => return @floatCast(value),
        else => @compileError("Unrecognized float type..."),
    }
}

pub fn betaPdf(comptime F: type, x: F, alpha: F, beta: F) F {
    if (alpha <= 0) {
        @panic("Parameter `alpha` must be greater than 0.");
    }
    if (beta <= 0) {
        @panic("Parameter `beta` must be greater than 0.");
    }

    var value: f64 = 0.0;
    if (x < 0.0 or x > 1.0) {
        value = 0.0;
    } else {
        // zig fmt: off
        value = math.pow(f64, x, alpha - 1.0)
            * math.pow(f64, 1.0 - x, beta - 1.0)
            / spec_fn.beta(alpha, beta);
        // zig fmt: on
    }

    switch (F) {
        f64 => return value,
        f32 => return @floatCast(value),
        else => @compileError("Unrecognized float type..."),
    }
}

pub fn betaLnPdf(comptime F: type, x: F, alpha: F, beta: F) F {
    if (alpha <= 0) {
        @panic("Parameter `alpha` must be greater than 0.");
    }
    if (beta <= 0) {
        @panic("Parameter `beta` must be greater than 0.");
    }

    var value: f64 = 0.0;
    if (x < 0.0 or x > 1.0) {
        value = math.inf_f64;
    } else {
        // zig fmt: off
        value = (alpha - 1.0) * @log(x)
            + (beta - 1.0) * @log(1.0 - x)
            - spec_fn.lnBeta(alpha, beta);
        // zog fmt: on
    }

    switch (F) {
        f64 => return value,
        f32 => return @floatCast(value),
        else => @compileError("Unrecognized float type..."),
    }
}
