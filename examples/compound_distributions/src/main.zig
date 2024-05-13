// Example: Sampling from compund distributions: Beta-Binomial, Multinomial-Dirichlet,

const std = @import("std");
const zprob = @import("zprob");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.testing.expect(false) catch @panic("Memory leaked...");
        }
    }

    var env = try zprob.RandomEnvironment.init(allocator);
    defer env.deinit();

    // 1. Beta-Binomial Distribution

    // 1a. Set up parameters:
    const alpha: f64 = 5.0;
    const beta: f64 = 2.0;
    const n: u32 = 20;
    const size: usize = 1000;

    // 1b. Generate Beta deviates first
    const beta_samples = try env.rBetaSlice(size, alpha, beta);
    defer allocator.free(beta_samples);

    // 1c. Use th beta samples as the probability of success in the
    //     Binomial distribution.
    var beta_bin_samples = try allocator.alloc(u32, size);
    defer allocator.free(beta_bin_samples);
    for (beta_samples, 0..) |b, i| {
        beta_bin_samples[i] = env.rBinomial(n, b);
    }

    std.debug.print(
        "\nBeta-Binomial Sample:\n{any}\n\n",
        .{beta_bin_samples},
    );
}
