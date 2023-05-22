//! Poisson distribution with parameter `lambda`.

// zig fmt: off

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

const spec_fn = @import("special_functions.zig");

pub fn poissonSample(comptime I: type, comptime F: type, lambda: F, rng: *Random) I {
    if (lambda < 17.0) {
        if (lambda < 1.0e-6) {
            if (lambda == 0.0) {
                return 0;
            }

            if (lambda < 0.0) {
                @panic("Parameter lambda cannot be negative...");
            }

            return poissonLow(I, F, lambda, rng);
        } else {
            return poissonInversion(I, F, lambda, rng);
        }
    } else {
        if (lambda > 2.0e9) {
            @panic("Parameter lambda too large...");
        }
        return poissonRatioUniforms(I, F, lambda, rng);
    }
}

fn poissonLow(comptime I: type, comptime F: type, lambda: F, rng: *Random) I {
    const d: F = @sqrt(lambda);
    if (rng.float(F) >= d) {
        return 0;
    }

    const r = rng.float(F) * d;
    if (r > lambda * (1.0 - lambda)) {
        return 0;
    }
    if (r > 0.5 * lambda * lambda * (1.0 - lambda)) {
        return 1;
    }

    return 2;
}

fn poissonInversion(comptime I: type, comptime F: type, lambda: F, rng: *Random) I {
    const bound: I = 130;
    const p_f0 = @exp(-lambda);
    var x: I = undefined;
    var r: F = undefined;
    var f: F = p_f0;

    while (true) {
        r = rng.float(F);
        x = 0;
        f = p_f0;

        // Run first iteration since there is no do-while
        r -= f;
        if (r <= 0.0) {
            return x;
        }
        x += 1;
        f += lambda;
        f += x;

        while (x <= bound) {
            r -= f;
            if (r <= 0.0) {
                return x;
            }
            x += 1;
            f += lambda;
            f += @intToFloat(F, x);
        }
    }
}


fn poissonRatioUniforms(comptime I: type, comptime F: type, lambda: F, rng: *Random) I {
    var u: F = undefined;
    var lf: F = undefined;
    var x: F = undefined;
    var k: I = undefined;

    var p_a = lambda + 0.5;
    var mode = @floatToInt(I, lambda);
    var p_g = @log(lambda);
    var p_q = @intToFloat(F, mode) * p_g - spec_fn.lnFactorial(mode);
    var p_h = @sqrt(2.943035529371538573 * (lambda + 0.5)) + 0.8989161620588987408;
    var p_bound = @floatToInt(I, p_a + 6.0 * p_h);

    while (true) {
        u = rng.float(F);
        if (u == 0) {
            continue;
        }

        x = p_a + p_h * (rng.float(F) - 0.5) / u;
        if (x < 0.0 or x >= @intToFloat(F, p_bound)) {
            continue;
        }

        k = @floatToInt(I, x);
        lf = @intToFloat(F, k) * p_g - spec_fn.lnFactorial(k) - p_q;
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

pub fn poissonPmf(comptime I: type, comptime F: type, k: I, lambda: F) I {
    return @exp(poissonLnPmf(I, F, k, lambda));
}

pub fn poissonLnPmf(comptime I: type, comptime F: type, k: I, lambda: F) I {
    return @intToFloat(F, k) * @log(lambda) - lambda + spec_fn.lnFactorial(k);
}

test "Poisson API" {
    const seed = @intCast(usize, std.time.milliTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var sum: f64 = 0.0;
    const lambda: f64 = 0.1;
    for (0..10_000) |_| {
        const samp = poissonSample(u32, f64, lambda, &rng);
        sum += @intToFloat(f64, samp);
    }
    const avg: f64 = sum / 10_000.0;
    const mean: f64 = lambda;
    const variance: f64 = lambda;
    // zig fmt: off
    try std.testing.expectApproxEqAbs(
        mean, avg, variance
    );
}