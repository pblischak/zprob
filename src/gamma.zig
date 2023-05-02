//! Gamma distribution with parameters `alpha` and `beta`.

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

const spec_fn = @import("special_functions.zig");

pub fn gammaSample(alpha: f64, beta: f64, rng: *Random) f64 {
    const log4: f64 = 1.3862943611198906;
    const sg_magic_const: f64 = 2.5040773967762740;

    if (alpha > 1.0) {
        // R.C.H. Cheng, "The generation of Gamma variables with non-integral shape parameters",
        // Applied Statistics, (1977), 26, No. 1, p71-74.
        const ainv: f64 = @sqrt(2.0 * alpha - 1.0);
        const b: f64 = alpha - log4;
        const c: f64 = alpha + ainv;
        while (true) {
            var unif1: f64 = rng.float(f64);
            if (!(1.0e-7 < unif1 and unif1 < 0.9999999)) {
                continue;
            }
            var unif2: f64 = 1.0 - rng.float(f64);
            var v: f64 = @log(unif1 / (1.0 - unif1)) / ainv;
            var x: f64 = alpha * @exp(v);
            var z: f64 = unif1 * unif1 * unif2;
            var t: f64 = b + c * v - x;
            if (t + sg_magic_const - 4.5 * z >= 0 or t >= @log(z)) {
                return x * beta;
            }
        }
    } else {
        var x: f64 = 0.0;
        while (true) {
            var unif1: f64 = rng.float(f64);
            var b: f64 = (math.e + alpha) / math.e;
            var p: f64 = b * unif1;
            if (p <= 1.0) {
                x = math.pow(f64, p, 1.0 / alpha);
            } else {
                x = -@log((b - p) / alpha);
            }
            var unif2: f64 = rng.float(f64);
            if (p > 1.0) {
                if (unif2 <= math.pow(f64, x, alpha - 1.0)) {
                    break;
                }
            } else if (unif2 <= @exp(-x)) {
                break;
            }
        }
        return x * beta;
    }
}

pub fn gammaPdf(x: f64, alpha: f64, beta: f64) f64 {
    if (x <= 0) {
        @panic("Parameter `x` must be greater than 0.");
    }
    const gamma_val = try spec_fn.gammaFn(alpha);
    // zig fmt: off
    const value = math.pow(f64, x, alpha - 1.0) * @exp(-beta * x)
        * math.pow(f64, beta, alpha) / gamma_val;
    // zig fmt: on
    return value;
}

pub fn gammaLnPdf(x: f64, alpha: f64, beta: f64) f64 {
    if (x <= 0) {
        @panic("Parameter `x` must be greater than 0.");
    }
    const ln_gamma_val = try spec_fn.lnGammaFn(alpha);
    // zig fmt: off
    const value = (alpha - 1.0) * @log(x) - beta * x + alpha
        * @log(beta) - ln_gamma_val;
    // zig fmt: on
    return value;
}
