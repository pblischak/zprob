//! Special functions used for implementing probability distributions.

const std = @import("std");
const math = std.math;

const utils = @import("utils.zig");

const Error = error{
    /// n < 0 (cannot be equal to 0)
    NegativeN,
    /// k < 0 (cannot be equal to 0)
    NegativeK,
    /// n < k
    NLessThanK,
    /// n <= 0
    NonPositiveN,
    /// k <= 0
    NonPositiveK,
};

/// Natural log-converted binomial coefficient for integers n and k.
pub fn lnNChooseK(comptime I: type, comptime F: type, n: I, k: I) Error!F {
    _ = utils.ensureFloatType(F);
    _ = utils.ensureIntegerType(I);
    check_n_k(I, n, k) catch |err| {
        return err;
    };

    // Handle simple cases when n == 0, n == 1, or n == k
    if (n == 0) return 0.0;
    if (n == 1) return @as(F, @floatFromInt(k));
    if (n == k) return 1.0;

    const val1 = try lnFactorial(I, F, n);
    const val2 = try lnFactorial(I, F, k);
    const val3 = try lnFactorial(I, F, n - k);

    const res = val1 - (val2 + val3);

    return res;
}

/// Binomial coefficient for integers n and k.
pub fn nChooseK(comptime I: type, n: I, k: I) Error!I {
    _ = utils.ensureIntegerType(I);
    check_n_k(I, n, k) catch |err| {
        return err;
    };
    const res = try lnNChooseK(I, f64, n, k);
    return @as(I, @intFromFloat(@exp(res)));
}

pub fn lnFactorial(comptime I: type, comptime F: type, n: I) Error!F {
    _ = utils.ensureFloatType(F);
    _ = utils.ensureIntegerType(I);
    if (n < 0) {
        return Error.NegativeN;
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

fn check_n_k(comptime I: type, n: I, k: I) Error!void {
    _ = utils.ensureIntegerType(I);

    if (n <= 0) {
        return Error.NonPositiveN;
    }
    if (k < 0) {
        return Error.NegativeK;
    }
    if (n < k) {
        return Error.NLessThanK;
    }
}

pub fn lnBetaFn(comptime F: type, a: F, b: F) F {
    _ = utils.ensureFloatType(F);

    const val1 = math.lgamma(F, a);
    const val2 = math.lgamma(F, b);
    const val3 = math.lgamma(F, a + b);
    return val1 + val2 - val3;
}

pub fn betaFn(comptime F: type, a: F, b: F) F {
    _ = utils.ensureFloatType(F);

    const val1 = math.lgamma(F, a);
    const val2 = math.lgamma(F, b);
    const val3 = math.lgamma(F, a + b);
    return @exp(val1 + val2 - val3);
}

test "Beta function" {
    var x: f64 = 10.0;
    std.debug.print("\n", .{});
    while (x <= 100.0) : (x += 10.0) {
        std.debug.print(
            "{}\t{}\n",
            .{
                x,
                betaFn(f64, x, x / 3.0),
            },
        );
    }
}

test "lnFactorial: n < 0" {
    const val = lnFactorial(i32, f32, -2);
    try std.testing.expectError(error.NegativeN, val);
}

test "check_n_k: n < 0" {
    const val = check_n_k(i32, -1, 10);
    try std.testing.expectError(error.NonPositiveN, val);
}

test "check_n_k: k < 0" {
    const val = check_n_k(i32, 10, -1);
    try std.testing.expectError(error.NegativeK, val);
}

test "check_n_k: n < k" {
    const val = check_n_k(i32, 10, 13);
    try std.testing.expectError(error.NLessThanK, val);
}
