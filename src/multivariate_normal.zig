//! Multivariate normal distribution with mean vector `mu_vec` and variance-covariance
//! matrix `sigma_mat`.

// zig fmt: off

const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;
const test_allocator = std.testing.allocator;

pub fn MultivariateNormal(comptime F: type) type {
    return struct{
        const Self = @This();

        prng: *Random,
        allocator: Allocator,

        pub fn init(prng: *Random, allocator: Allocator) Self {
            return Self{
                .prng = prng,
                .allocator = allocator,
            };
        }

        pub fn sample(self: Self, mu_vec: []F, sigma_mat: []F, out_vec: []F) !void {
            if (sigma_mat.len != (mu_vec.len * mu_vec.len)) {
                @panic(
                    \\ Mean vector and variance covariance matrix are incorrectly sized.
                    \\ Must be N and N x N, respectively.
                );
            }

            if (mu_vec.len != out_vec.len) {
                @panic("Mean vector and out vector must be the same size.");
            }
            const n = mu_vec.len;
            var ae: F = undefined;
            var icount: usize = undefined;

            var work = try self.allocator.alloc(F, n);
            for (0..n) |i| {
                work[i] = self.prng.floatNorm(F);
            }
            defer self.allocator.free(work);

            // Get Cholesky deomposition of sigma_mat
            cholesky(sigma_mat, n);

            // Store L from Cholesky decomp as an upper triangular matrix
            var upper = ArrayList(F).init(self.allocator);
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
                    ae += upper.items[i + n * j - icount] * work[j];
                }
                out_vec[i] = ae + mu_vec[i];
            }
        }
    };
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

    std.debug.print("\n{any}\n", .{arr});
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
    // var out_vec = [3]f64{ 0.0, 0.0, 0.0 };
    var sm = [4]f64{ 2.0, -1.0, -1.0, 4.0};
    var mu = [2]f64{ 5.0, 9.5 };
    var out_vec = [2]f64{ 0.0, 0.0 };
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var mv_norm = MultivariateNormal(f64).init(&rng, test_allocator);
    const tt = try mv_norm.sample(mu[0..], sm[0..], out_vec[0..]);
    std.debug.print("\n{any}\n", .{tt});
}
