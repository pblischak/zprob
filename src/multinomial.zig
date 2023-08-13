//! Multinomial distribution with parameters `n` (number of totol observations), `n_cat`
//! (number of categories), and `p_vec` (probability of observing each category).

// zig fmt: off

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;

const Binomial = @import("binomial.zig").Binomial;
const spec_fn = @import("special_functions.zig");

pub fn Multinomial(comptime I: type, comptime F: type) type {
    return struct {
        const Self = @This();

        prng: *Random,

        pub fn init(prng: *Random) Self {
            return Self{
                .prng = prng,
            };
        }

        pub fn sample(self: Self, n: I, n_cat: usize, p_vec: []F, out_vec: []I) void {
            if (p_vec.len != n_cat) {
                @panic("Number of categories and length of probability vector are not the same...");
            }

            if (p_vec.len != out_vec.len) {
                @panic("Length of probability and output vectors are not the same...");
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

            for (0..n_cat) |i| {
                out_vec[i] = 0;
            }

            var binomial = Binomial(I, F).init(self.prng);

            for (0..(n_cat - 1)) |icat| {
                prob = p_vec[icat] / p_tot;
                out_vec[icat] = binomial.sample(n_tot, prob);
                n_tot -= out_vec[icat];
                if (n_tot <= 0) {
                    return;
                }
                p_tot -= p_vec[icat];
            }
            out_vec[n_cat - 1] = n_tot;
        }


        pub fn pmf(x_vec: []I, p_vec: []F) F {
            return @exp(lnPmf(I, F, x_vec, p_vec));
        }

        pub fn lnPmf(x_vec: []I, p_vec: []F) F {
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
    };
}

test "Multinomial API" {
    const DefaultPrng = std.rand.Xoshiro256;
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();
    var multinomial = Multinomial(i32, f64).init(&rng);
    var p_vec = [3]f64{ 0.1, 0.25, 0.65 };
    var out_vec = [3]i32{ 0, 0, 0 };
    multinomial.sample(10, 3, p_vec[0..], out_vec[0..]);
    std.debug.print("\n{any}\n", .{out_vec});
}
