//! Chi-squared distribution with degrees of freedom `k`.

// zig fmt: off

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

const gammaSample = @import("gamma.zig").gammaSample;
const lnGammaFn = @import("special_functions.zig").lnGammaFn;

pub fn chiSquaredSample(comptime I: type, comptime F: type, k: I, rng: *Random) F {
    const b = @intToFloat(F, k) / 2.0;
    const k_usize = @intCast(usize, k);

    var x2: F = undefined;
    var x: F = undefined;
    if (k <= 100) {
        x2 = 0.0;
        for (0..k_usize) |_| {
            x = rng.floatNorm(F);
            x2 += x * x;
        }
    } else {
        x2 = gammaSample(F, b, 0.5, rng);
    }

    return x2;
}

pub fn chiSquaredPdf(comptime I: type, comptime F: type, k: I, x: F) F {
    if (x < 0.0) {
        return 0.0;
    }

    return @exp(chiSquaredLnPdf(I, F, k, x));
}

pub fn chiSquaredLnPdf(comptime I: type, comptime F: type, k: I, x: F) F {
    var b: F = @intToFloat(F, k) / 2.0;
    return -(b * @log(2.0) + lnGammaFn(F, b)) - b + (b - 1.0) * @log(x);
}

test "Chi-squared API" {
    const seed = @intCast(u64, std.time.microTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var sum: f64 = 0.0;
    for (0..10_000) |_| {
        sum += chiSquaredSample(i32, f64, 10, &rng);
    }
    const avg = sum / 10_000.0;
    std.debug.print("{}\n", .{avg});
}