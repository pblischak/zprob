// Example: Sampling from distributions and summarizing results.

const std = @import("std");
const zprob = @import("zprob");
const binomial = zprob.default_binomial;

pub fn main() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    var rand = prng.random();

    var sample: u32 = 0;
    for (0..100) |_| {
        sample = try binomial.sample(50, 0.5, &rand);
        std.debug.print("{}\n", .{sample});
    }
}
