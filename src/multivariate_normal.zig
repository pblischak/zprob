//! Multivariate normal distribution with mean vector `mu_vec` and variance-covariance
//! matrix `sigma_mat`.

// zig fmt: off

const std = @import("std");
const math = std.math;
const ArrayList = std.ArrayList;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;
const test_allocator = std.testing.allocator;

pub fn mvNormalSample(
    comptime T: type, mu_vec: []T, sigma_mat: []T, rng: *Random, alloc: std.mem.Allocator
) !ArrayList(T) {
    if (sigma_mat.len != (mu_vec.len * mu_vec.len)) {
        @panic(
            \\ Mean vector and variance covariance matrix are incorrectly sized.
            \\ Must be N and N x N, respectively.
        );
    }
    const n = mu_vec.len;
    var ae: T = undefined;
    var icount: usize = undefined;

    var work = ArrayList(T).init(alloc);
    for (0..n) |_| {
        try work.append(rng.floatNorm(T));
    }
    defer work.deinit();
    var result = ArrayList(T).init(alloc);

    // Get Cholesky deomposition of sigma_mat
    cholesky(sigma_mat, n);

    // Store L from Cholesky decomp as an upper triangular matrix
    var upper = ArrayList(T).init(alloc);
    defer upper.deinit();
    for (0..n) |i| {
        for (i..n) |j| {
            try upper.append(sigma_mat[i + j * n]);
        }
    }

    for (0..n) |i| {
        icount = 0;
        ae = 0.0;
        for (0..(i + 1)) |j| {
            icount += j;
            ae += upper.items[i + n * j - icount] * work.items[j];
        }
        try result.append(ae + mu_vec[i]);
    }

    return result;
}

pub fn mvNormalLnPdf(
    comptime T: type, x_vec: []T, mu_vec: []T, sigma_mat: []T, alloc: std.mem.Allocator
) !T {
    if (
        sigma_mat.len != (mu_vec.len * mu_vec.len)
        and sigma_mat.len != (x_vec.len * x_vec.len)
    ) {
        @panic(
            \\ X vector, mean vector, and variance covariance matrix are incorrectly sized.
            \\ Must be N, N, and N x N, respectively.
        );
    }
    _ = ArrayList(T).init(alloc);
    @panic("Not implemented yet...");
}

/// Cholesky-Banachiewicz algorithm for Cholesky decomposition.
/// 
/// For a square, positive-definite matrix A, the Cholesky decomposition
/// returns a factorized, lower triangular matrix, L, such that A = L * L'.
/// 
/// Note: This algorithm modifies the original matrix *in place*.
fn cholesky(a: []f64, n: usize) void {
    var sum: f64 = undefined;
    for (0..n) |i| {
        for (0..(i + 1)) |j| {
            sum = 0.0;
            for (0..j) |k| {
                sum += a[i * n + k] * a[j * n + k];
            }

            if (i == j) {
                a[i * n + j] = @sqrt(a[i * n + i] - sum);
            } else {
                a[i * n + j] = (1.0 / a[j * n + j] * (a[i * n + j] - sum));
            }
        }
    }
}

test "Cholesky–Banachiewicz algorithm" {
    var arr = [_]f64{
        4, 12, -16,
        12, 37, -43,
        -16, -43, 98,
    };

    std.debug.print("\n{any}", .{arr});
    cholesky(arr[0..], 3);
    for (0..3) |i| {
        for (0..3) |j| {
            std.debug.print("{}, ", .{arr[i * 3 + j]});
        }
        std.debug.print("\n", .{});
    }
}

test "Multivariate Normal API" {
    // var sm = [9]f64{ 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0 };
    // var mu = [3]f64{ 5.0, 9.5, 2.0 };
    var sm = [4]f64{ 2.0, -1.0, -1.0, 4.0};
    var mu = [2]f64{ 5.0, 9.5 };
    const seed = @intCast(u64, std.time.microTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    const tt = try mvNormalSample(f64, mu[0..], sm[0..], &rng, test_allocator);
    defer tt.deinit();
    std.debug.print("\n{any}", .{tt});
}
