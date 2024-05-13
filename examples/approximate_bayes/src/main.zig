//! Example: Approximate Bayesian computation for estimating Normal mean and stddev.

const std = @import("std");
const zprob = @import("zprob");
const Allocator = std.mem.Allocator;

const data = [_]f64{
    7.34680950,
    0.34706467,
    4.54353802,
    3.56277385,
    4.31746622,
    0.13882361,
    3.49092044,
    4.16228808,
    3.38676354,
    3.60579725,
    2.75215646,
    2.11193977,
    0.41275589,
    2.78941058,
    8.79130642,
    4.61324429,
    0.78828381,
    4.56085007,
    6.22148066,
    3.23846641,
    6.54692797,
    5.22677536,
    4.14605683,
    4.82796343,
    1.60849630,
    3.06535905,
    5.97360764,
    5.83990871,
    6.66210485,
    5.27896250,
    3.90218349,
    2.53175582,
    0.66375654,
    1.67895720,
    6.23917976,
    2.44751878,
    3.38133793,
    5.37992424,
    5.15140756,
    1.41627808,
    1.73235902,
    5.75548239,
    -0.07483746,
    6.39103795,
    3.12569470,
    3.91939935,
    3.18286682,
    7.05816813,
    1.98442496,
    3.70440806,
    1.63864067,
    2.08689758,
    4.30950935,
    2.68511037,
    4.42336686,
    6.38787263,
    2.24322145,
    1.90580495,
    3.51549164,
    5.31737497,
    3.42222977,
    6.61149370,
    6.82002483,
    9.39360392,
    4.30905480,
    2.76504444,
    3.47781502,
    5.22433513,
    3.81521563,
    8.19750514,
    3.51295017,
    8.24990916,
    6.67240851,
    6.20703582,
    2.57117110,
    2.83407378,
    4.57217350,
    1.97180962,
    4.67436022,
    3.94532825,
    3.94702154,
    3.71043232,
    2.33728054,
    4.47787195,
    4.62494548,
    0.72597433,
    2.83977687,
    6.75008453,
    3.19768612,
    8.61298770,
    0.76683280,
    2.16365165,
    4.13570924,
    6.33341552,
    2.23632087,
    5.33096460,
    0.09848001,
    5.27894279,
    5.90737181,
    5.91558769,
};

/// Store distance value and current index for use after sorting.
const Distance = struct {
    value: f64,
    idx: usize,

    /// Sort `Distance`s by value.
    fn lessThan(context: void, a: Distance, b: Distance) bool {
        _ = context;
        return a.value < b.value;
    }
};

/// Euclidean distance.
fn dist(x_vec: []const f64, y_vec: []const f64) f64 {
    std.debug.assert(x_vec.len == y_vec.len);
    var accum: f64 = 0.0;
    for (x_vec, y_vec) |x, y| {
        accum += (x - y) * (x - y);
    }
    return @sqrt(accum);
}

pub fn main() !void {
    // Number of prior samples to draw
    const NSAMPLES: usize = 100_000;
    // Number of prior samples to save for estimation
    const NSAVE: usize = 250;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
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

    // Generate uniform samples for normal mean
    const mu_prior = try env.rUniformSlice(NSAMPLES, -10.0, 10.0);
    defer allocator.free(mu_prior);

    // Generate uniform samples for normal stddev
    const sigma_prior = try env.rUniformSlice(NSAMPLES, 0.0, 20.0);
    defer allocator.free(sigma_prior);

    // Initialize vector to store euclidean distances between simulated data
    // and the observed data
    var distances = try allocator.alloc(Distance, NSAMPLES);
    defer allocator.free(distances);

    // Initialize vector to store simulated data
    var sim_data = try allocator.alloc(f64, data.len);
    defer allocator.free(sim_data);

    for (mu_prior, sigma_prior, 0..) |mu, sigma, i| {
        for (0..data.len) |j| {
            sim_data[j] = env.rNormal(mu, sigma);
        }
        distances[i] = Distance{
            .value = dist(data[0..], sim_data[0..]),
            .idx = i,
        };
    }

    std.debug.print("{any}\t{any}\n", .{ distances[0], distances[1] });

    // In-place sorting of distances
    std.sort.block(Distance, distances[0..], {}, Distance.lessThan);

    std.debug.print("{any}\t{any}\n", .{ distances[0], distances[1] });

    // Loop through 100 lowest distances and use the index to get the corresponding
    // means and stddevs from the priors. Use them to estimate posterior means for
    // the parameters
    std.debug.print("Mu\tSigma\n", .{});
    var mu_mean: f64 = 0.0;
    var sigma_mean: f64 = 0.0;
    for (0..NSAVE) |i| {
        const idx = distances[i].idx;
        mu_mean += mu_prior[idx];
        sigma_mean += sigma_prior[idx];
        std.debug.print("{}\t{}\n", .{ mu_prior[idx], sigma_prior[idx] });
    }
    std.debug.print(
        "\n\nMu Mean: {},\tSigma Mean: {}\n",
        .{
            mu_mean / @as(f64, @floatFromInt(NSAVE)),
            sigma_mean / @as(f64, @floatFromInt(NSAVE)),
        },
    );
}
