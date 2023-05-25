//! Gamma distribution with parameters `alpha` and `beta`.

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

const spec_fn = @import("special_functions.zig");

pub fn gammaSample(comptime F: type, alpha: F, beta: F, rng: *Random) F {
    const log4: F = @as(F, 1.3862943611198906);
    const sg_magic_const: F = @as(F, 2.5040773967762740);

    if (alpha > 1.0) {
        // R.C.H. Cheng, "The generation of Gamma variables with non-integral shape parameters",
        // Applied Statistics, (1977), 26, No. 1, p71-74.
        const ainv: F = @sqrt(2.0 * alpha - 1.0);
        const b: F = alpha - log4;
        const c: F = alpha + ainv;
        while (true) {
            var unif1: F = rng.float(F);
            if (!(1.0e-7 < unif1 and unif1 < 0.9999999)) {
                continue;
            }
            var unif2: F = 1.0 - rng.float(F);
            var v: F = @log(unif1 / (1.0 - unif1)) / ainv;
            var x: F = alpha * @exp(v);
            var z: F = unif1 * unif1 * unif2;
            var t: F = b + c * v - x;
            if (t + sg_magic_const - 4.5 * z >= 0 or t >= @log(z)) {
                const value = x * beta;
                return value;
            }
        }
    } else {
        var x: F = 0.0;
        while (true) {
            var unif1: F = rng.float(F);
            var b: F = (math.e + alpha) / math.e;
            var p: F = b * unif1;
            if (p <= 1.0) {
                x = math.pow(F, p, 1.0 / alpha);
            } else {
                x = -@log((b - p) / alpha);
            }
            var unif2: F = rng.float(F);
            if (p > 1.0) {
                if (unif2 <= math.pow(F, x, alpha - 1.0)) {
                    break;
                }
            } else if (unif2 <= @exp(-x)) {
                break;
            }
        }
        const value = x * beta;
        return value;
    }
}

pub fn gammaPdf(comptime F: type, x: F, alpha: F, beta: F) F {
    if (x <= 0) {
        @panic("Parameter `x` must be greater than 0.");
    }
    const gamma_val = try spec_fn.gammaFn(F, alpha);
    // zig fmt: off
    const value = math.pow(F, x, alpha - 1.0) * @exp(-beta * x)
        * math.pow(F, beta, alpha) / gamma_val;
    // zig fmt: on

    return value;
}

pub fn gammaLnPdf(comptime F: type, x: F, alpha: F, beta: F) F {
    if (x <= 0) {
        @panic("Parameter `x` must be greater than 0.");
    }
    const ln_gamma_val = try spec_fn.lnGammaFn(F, alpha);
    // zig fmt: off
    const value = (alpha - 1.0) * @log(x) - beta * x + alpha
        * @log(beta) - ln_gamma_val;
    // zig fmt: on
    return value;
}
