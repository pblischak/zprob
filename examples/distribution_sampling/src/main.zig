// Example: Sampling from distributions and summarizing results.

const std = @import("std");
const zprob = @import("zprob");

pub fn main() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    var rand = prng.random();
    var binomial = zprob.Binomial(i32, f64).init(&rand);

    var sample: i32 = 0;
    for (0..100) |_| {
        sample = binomial.sample(50, 0.5);
        std.debug.print("{}\n", .{sample});
    }
}
