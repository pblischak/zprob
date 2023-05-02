const std = @import("std");
const zprob = @import("zprob");
const DefaultPrng = std.rand.Xoshiro256;

pub fn main() void {
    const seed = @intCast(u64, std.time.microTimestamp());
    var prng = DefaultPrng.init(seed);
    var rng = prng.random();

    var sample: i32 = 0;
    for (0..100) |_| {
        sample = zprob.binomialSample(50, 0.5, &rng);
        std.debug.print("{}\n", .{sample});
    }
}
