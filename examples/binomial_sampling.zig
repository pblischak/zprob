const std = @import("std");
const zprob = @import("zprob");
const DefaultPrng = std.rand.Xoshiro256;

pub fn main() !void {
    var prng = DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    var rng = prng.random();

    var sample: i32 = 0;
    for (0..100) |_| {
        sample = zprob.binomialSample(i32, f64, 50, 0.5, &rng);
        std.debug.print("{}\n", .{sample});
    }
}
