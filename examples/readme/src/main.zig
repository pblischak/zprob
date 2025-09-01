// Example: README code snippets.

const std = @import("std");
const zprob = @import("zprob");

pub fn main() !void {

    // *** RandomEnvironment API Example***
    // Set up main memory allocator and defer deinitilization
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const status = gpa.deinit();
        std.testing.expect(status == .ok) catch {
            @panic("Memory leak!");
        };
    }

    // Set up random environment and defer deinitialization
    var env = try zprob.RandomEnvironment.init(allocator);
    defer env.deinit();

    // Generate random samples
    const binomial_sample = try env.rBinomial(10, 0.8);
    const geometric_sample = try env.rGeometric(0.3);
    std.debug.print("b = {};\tg = {}\n", .{ binomial_sample, geometric_sample });

    // Generate slices of random samples. The caller is responsible for cleaning up
    // the allocated memory for the slice.
    const binomial_slice = try env.rBinomialSlice(100, 20, 0.4);
    defer allocator.free(binomial_slice);

    // ***Distributions API Example***
    // Set up random generator.
    const seed: u64 = @intCast(std.time.microTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    // Same as: `const beta = zprob.Beta(f64){}`;
    const beta = zprob.default_beta;
    // Same as: `const binomial = zprob.Binomial(u32, f64){}`
    const binomial = zprob.default_binomial;

    var b1: f64 = undefined;
    var b2: u32 = undefined;
    for (0..100) |_| {
        b1 = try beta.sample(1.0, 5.0, &rand);
        b2 = try binomial.sample(20, b1, &rand);
    }
}
