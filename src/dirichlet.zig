//! Dirichlet distribution with parameter `alpha_vec`.

// zig fmt: off

const std = @import("std");
const math = std.math;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;
const test_allocator = std.testing.allocator;

const gammaSample = @import("gamma.zig").gammaSample;
const lnGammaFn = @import("special_functions.zig").lnGammaFn;

pub fn dirichletSample(
    comptime F: type, alpha_vec: []F, rng: *Random, allocator: Allocator
) ![]F {
    var x_vec = try allocator.alloc(F, alpha_vec.len);
    var sum: F = 0.0;
    for (alpha_vec, 0..) |alpha, i| {
        x_vec[i] = gammaSample(F, alpha, 1.0, rng);
        sum += x_vec[i];
    }

    for (x_vec) |*x| {
        x.* /= sum;
    }

    return &x_vec;
}

pub fn dirichletPdf(comptime F: type, x_vec: []F, alpha_vec: []F) F {
    return @exp(lnDirichletPdf(F, x_vec, alpha_vec));
}

pub fn lnDirichletPdf(comptime F: type, x_vec: []F, alpha_vec: []F) F {
    var numerator: F = 0.0;

    for (x_vec, 0..) |x, i| {
        numerator += (alpha_vec[i] - 1.0) * @log(x);
    }

    return numerator - lnMultivariateBeta(F, alpha_vec);
}

fn lnMultivariateBeta(comptime F: type, alpha_vec: []F) F {
    var numerator: F = undefined;
    var alpha_sum: F = 0.0;

    for (alpha_vec) |alpha| {
        numerator += lnGammaFn(F, alpha);
        alpha_sum += alpha;
    }

    return numerator - lnGammaFn(F, alpha_sum);
}

fn multivariateBeta(comptime F: type, alpha_vec: []F) F {
    return @exp(lnMultivariateBeta(F, alpha_vec));
}
