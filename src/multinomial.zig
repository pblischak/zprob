//! Multinomial distribution with parameters `n` (number of totol observations), `n_cat`
//! (number of categories), and `p_vec` (probability of observing each category).

// zig fmt: off

const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;
const test_allocator = std.testing.allocator;

const binomialSample = @import("binomial.zig").binomialSample;
const spec_fn = @import("special_functions.zig");

pub fn multinomialSample(
    comptime I: type, comptime F: type,
    n: I, n_cat: I, p_vec: []F, rng: *Random, allocator: Allocator
) ![]I {
    if (p_vec.len != n_cat) {
        @panic("Number of categories and length of probability vector are not the same...");
    }

    var p_sum: F = 0.0;
    for (p_vec) |p| {
        p_sum += p;
    }

    if (!math.approxEqRel(F, 1.0, p_sum, @sqrt(math.floatEps(F)))) {
        std.debug.print("\n{}\n", .{p_sum});
        @panic("Probabilities in p_vec do not sum to 1.0...");
    }

    var p_tot: F = 1.0;
    var n_tot = n;
    var prob: F = undefined;

    // Make a usize of n_cat to use in loops
    const n_cat_usize: usize = @intCast(n_cat);

    var ix = try allocator.alloc(I, n_cat_usize);
    for (0..n_cat_usize) |i| {
        ix[i] = 0;
    }

    for (0..(n_cat_usize - 1)) |icat| {
        prob = p_vec[icat] / p_tot;
        ix[icat] = binomialSample(I, F, n_tot, prob, rng);
        n_tot -= ix[icat];
        if (n_tot <= 0) {
            return ix;
        }
        p_tot -= p_vec[icat];
    }
    ix[n_cat_usize - 1] = n_tot;

    return ix[0..];
}

pub fn multinomialPmf(comptime I: type, comptime F: type, x_vec: []I, p_vec: []F) F {
    return @exp(multinomialLnPmf(I, F, x_vec, p_vec));
}

pub fn multinomialLnPmf(comptime I: type, comptime F: type, x_vec: []I, p_vec: []F) F {
    var n: I = 0;
    for (x_vec) |x| {
        n += x;
    }

    var coeff: F = spec_fn.lnFactorial(n);
    var probs: F = undefined;
    for (x_vec, 0..) |x, i| {
        coeff -= spec_fn.lnFactorial(x);
        probs += x * @log(p_vec[i]);
    }
    return coeff + probs;
}

test "Multinomial API" {
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var p_vec = [3]f64{ 0.1, 0.25, 0.65 };
    const res = try multinomialSample(i32, f64, 10, 3, p_vec[0..], &rng, test_allocator);
    defer test_allocator.free(res);
    std.debug.print("\n{any}\n", .{res});
}
