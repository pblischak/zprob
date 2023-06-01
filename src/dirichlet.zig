//! Dirichlet distribution with parameter `alpha_vec`.

// zig fmt: off

const std = @import("std");
const math = std.math;
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

    return x_vec[0..];
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

test "Dirichlet API" {
    const seed = @intCast(u64, std.time.microTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var alpha_vec = [3]f64{ 0.1, 0.1, 0.1 };
    // const alpha_sum = 0.3;
    var tmp: []f64 = undefined;
    var res: [3]f64 = [3]f64{ 0.0, 0.0, 0.0 };
    for (0..10_000) |_| {
        tmp = try dirichletSample(f64, alpha_vec[0..], &rng, test_allocator);
        defer test_allocator.free(tmp);
        res[0] += tmp[0];
        res[1] += tmp[1];
        res[2] += tmp[2];
    }
    res[0] /= 10_000.0;
    res[1] /= 10_000.0;
    res[2] /= 10_000.0;
    std.debug.print("\n{any}\n", .{res});
}