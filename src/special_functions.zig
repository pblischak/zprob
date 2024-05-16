//! Special functions used for implementing probability distributions.

const std = @import("std");
const math = std.math;

const utils = @import("utils.zig");

const log_root_2_pi: f64 = @log(@sqrt(2.0 * math.pi));

/// Natural log-converted binomial coefficient for integers n and k.
pub fn lnNChooseK(comptime I: type, comptime F: type, n: I, k: I) F {
    _ = utils.ensureFloatType(F);
    _ = utils.ensureIntegerType(I);
    check_n_k(I, n, k);

    // Handle simple cases when n == 0, n == 1, or n == k
    if (n == 0) return 0.0;
    if (n == 1) return @as(F, @floatFromInt(k));
    if (n == k) return 1.0;

    const res = lnFactorial(I, F, n) - (lnFactorial(I, F, k) + lnFactorial(I, F, n - k));

    return res;
}

/// Binomial coefficient for integers n and k.
pub fn nChooseK(comptime I: type, n: I, k: I) I {
    _ = utils.ensureIntegerType(I);
    check_n_k(I, n, k);
    const res = lnNChooseK(I, f64, n, k);
    return @as(I, @intFromFloat(@exp(res)));
}

pub fn lnFactorial(comptime I: type, comptime F: type, n: I) F {
    _ = utils.ensureFloatType(F);
    _ = utils.ensureIntegerType(I);
    if (n < 0) {
        @panic("Cannot take the log factorial of a negative number.");
    }

    if (n < 1024) {
        if (n <= 1) return 0;
        var sum: F = 0.0;
        var i: I = 1;
        while (i < n) : (i += 1) {
            sum += @log(@as(F, @floatFromInt(i)));
        }
        return sum;
    }

    // Sterling approximation
    const C0: F = 0.918938533204672722;
    const C1: F = 1.0 / 12.0;
    const C3: F = -1.0 / 360.0;
    const n1: F = @as(F, @floatFromInt(n));
    const r: F = 1.0 / n1;
    return (n1 + 0.5) * @log(n1) - n1 + C0 + r * (C1 + r * r * C3);
}

fn check_n_k(comptime I: type, n: I, k: I) void {
    _ = utils.ensureIntegerType(I);

    if (n < k) {
        @panic("Parameter `n` cannot be less than parameter `k`.");
    }
    if (n <= 0) {
        @panic("Parameter `n` cannot be less than or equal to 0");
    }
    if (k < 0) {
        @panic("Parameter `k` cannot be less than 0.");
    }
}

pub fn lnGammaFn(comptime F: type, x: F) !F {
    _ = utils.ensureFloatType(F);

    if (x < 0) {
        @panic("Parameter `x` cannot be less than 0.");
    }

    if (x < 10) {
        const gamma_val = try gammaFn(F, x);
        return @log(gamma_val);
    }

    return lnGammaLanczos(F, x);
}

fn lnGammaLanczos(comptime F: type, x: F) F {
    _ = utils.ensureFloatType(F);

    const lanczos_coeff = [9]F{
        0.99999999999980993227684700473478,
        676.520368121885098567009190444019,
        -1259.13921672240287047156078755283,
        771.3234287776530788486528258894,
        -176.61502916214059906584551354,
        12.507343278686904814458936853,
        -0.13857109526572011689554707,
        9.984369578019570859563e-6,
        1.50563273514931155834e-7,
    };

    var k: usize = 1;
    var accum: F = lanczos_coeff[0];
    var term1: F = 0.0;
    var term2: F = 0.0;

    const x1 = x - 1.0;

    while (k <= 8) : (k += 1) {
        accum += lanczos_coeff[k] / (x1 + @as(F, @floatFromInt(k)));
    }

    term1 = (x1 + 0.5) * @log((x1 + 7.5) / math.e);
    term2 = @as(F, @floatCast(log_root_2_pi)) + @log(accum);

    return term1 + (term2 - 7.0);
}

/// Calculate Gamma(x) using Spouge's approximation.
pub fn gammaFn(comptime F: type, x: F) !F {
    _ = utils.ensureFloatType(F);

    if (x < 0) {
        @panic("Parameter `x` cannot be less than 0.");
    }

    // TODO(paul): make the calculation of `c` happen at comptime
    const a: i32 = 12;
    const a_f: F = @as(F, @floatFromInt(a));
    var c = std.mem.zeroes([12]F);
    var k1_factorial: F = 1.0;
    var k: usize = 1;
    var k_f: F = 0.0;
    var accum: F = 0.0;

    c[0] = math.sqrt(2.0 * math.pi);
    while (k < a) : (k += 1) {
        k_f = @as(F, @floatFromInt(k));
        c[k] = @exp(a_f - k_f) * @as(F, @floatCast(math.pow(
            f64,
            @floatCast(a_f - k_f),
            @floatCast(k_f - 0.5),
        ))) / k1_factorial;
        k1_factorial *= -k_f;
    }

    accum = c[0];
    k = 1;
    while (k < a) : (k += 1) {
        k_f = @as(F, @floatFromInt(k));
        accum += c[k] / (x + k_f);
    }
    accum *= @exp(-(x + a_f)) * @as(F, @floatCast(math.pow(
        f64,
        @floatCast(x + a_f),
        @floatCast(x + 0.5),
    )));
    return accum / x;
}

/// Calculate Gamma(x) using the Sterling approximation.
pub fn fastGammaFn(comptime F: type, x: F) F {
    _ = utils.ensureFloatType(F);
    return @sqrt(2.0 * math.pi / x) * @as(F, @floatCast(math.pow(
        f64,
        @floatCast(x / math.e),
        @floatCast(x),
    )));
}

pub fn lnBetaFn(comptime F: type, a: F, b: F) !F {
    _ = utils.ensureFloatType(F);

    const val1 = try lnGammaFn(F, a);
    const val2 = try lnGammaFn(F, b);
    const val3 = try lnGammaFn(F, a + b);
    return val1 + val2 - val3;
}

pub fn betaFn(comptime F: type, a: F, b: F) !F {
    _ = utils.ensureFloatType(F);

    const val1 = try lnGammaFn(F, a);
    const val2 = try lnGammaFn(F, b);
    const val3 = try lnGammaFn(F, a + b);
    return @exp(val1 + val2 - val3);
}

test "Gamma function" {
    var x: f64 = 10.0;
    std.debug.print("\n", .{});
    while (x <= 100.0) : (x += 10.0) {
        std.debug.print(
            "{}\t{}\n",
            .{
                try gammaFn(f64, x / 3.0),
                fastGammaFn(f64, x / 3.0),
            },
        );
    }
}
