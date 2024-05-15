//! High-level API for simple random number sampling.
//!
//! The `RandomEnvironment` struct can automatically seed a pseudo-random number generator,
//! generate random deviates from discrete and continuous probabilitiy
//! distributions, and calculate probabilities with probability mass/density
//! functions.
//!
//! Functions that sample a slice of random deviates require the caller
//! to deallocate the memory.

const std = @import("std");
const Allocator = std.mem.Allocator;
const Random = std.Random;

const spec_fn = @import("special_functions.zig");
const utils = @import("utils.zig");

const Bernoulli = @import("bernoulli.zig").Bernoulli;
const Binomial = @import("binomial.zig").Binomial;
const Geometric = @import("geometric.zig").Geometric;
const Multinomial = @import("multinomial.zig").Multinomial;
const NegativeBinomial = @import("negative_binomial.zig").NegativeBinomial;
const Poisson = @import("poisson.zig").Poisson;
const UniformInt = @import("uniform.zig").UniformInt;
const Weighted = @import("sample.zig").Weighted;

const Beta = @import("beta.zig").Beta;
const Cauchy = @import("cauchy.zig").Cauchy;
const ChiSquared = @import("chi_squared.zig").ChiSquared;
const Dirichlet = @import("dirichlet.zig").Dirichlet;
const Exponential = @import("exponential.zig").Exponential;
const Gamma = @import("gamma.zig").Gamma;
const Normal = @import("normal.zig").Normal;
const Uniform = @import("uniform.zig").Uniform;

const Self = @This();

const RngState = struct {
    prng: std.rand.DefaultPrng,
    rand: Random,
};

seed: u64,
rng_state: *RngState,
allocator: Allocator,

bernoulli: Bernoulli(u32, f64),
binomial: Binomial(u32, f64),
geometric: Geometric(u32, f64),
multinomial: Multinomial(u32, f64),
negative_binomial: NegativeBinomial(u32, f64),
poisson: Poisson(u32, f64),
uniform_int: UniformInt(i32),
uniform_uint: UniformInt(u32),

beta: Beta(f64),
cauchy: Cauchy(f64),
chi_squared: ChiSquared(u32, f64),
dirichlet: Dirichlet(f64),
exponential: Exponential(f64),
gamma: Gamma(f64),
normal: Normal(f64),
uniform: Uniform(f64),

pub fn init(allocator: Allocator) !Self {
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));
    const rng_state = try allocator.create(RngState);
    rng_state.*.prng = std.Random.DefaultPrng.init(seed);
    rng_state.*.rand = rng_state.*.prng.random();
    return Self{
        .seed = seed,
        .rng_state = rng_state,
        .allocator = allocator,

        .bernoulli = Bernoulli(u32, f64).init(&rng_state.*.rand),
        .binomial = Binomial(u32, f64).init(&rng_state.*.rand),
        .geometric = Geometric(u32, f64).init(&rng_state.*.rand),
        .multinomial = Multinomial(u32, f64).init(&rng_state.*.rand),
        .negative_binomial = NegativeBinomial(u32, f64).init(&rng_state.*.rand),
        .poisson = Poisson(u32, f64).init(&rng_state.*.rand),
        .uniform_int = UniformInt(i32).init(&rng_state.*.rand),
        .uniform_uint = UniformInt(u32).init(&rng_state.*.rand),

        .beta = Beta(f64).init(&rng_state.*.rand),
        .cauchy = Cauchy(f64).init(&rng_state.*.rand),
        .chi_squared = ChiSquared(u32, f64).init(&rng_state.*.rand),
        .dirichlet = Dirichlet(f64).init(&rng_state.*.rand),
        .exponential = Exponential(f64).init(&rng_state.*.rand),
        .gamma = Gamma(f64).init(&rng_state.*.rand),
        .normal = Normal(f64).init(&rng_state.*.rand),
        .uniform = Uniform(f64).init(&rng_state.*.rand),
    };
}

pub fn initWithSeed(seed: u64, allocator: Allocator) !Self {
    const rng_state = try allocator.create(RngState);
    rng_state.*.prng = std.rand.DefaultPrng.init(seed);
    rng_state.*.rand = rng_state.*.prng.random();
    return Self{
        .seed = seed,
        .rng_state = rng_state,
        .allocator = allocator,

        .bernoulli = Bernoulli(u32, f64).init(&rng_state.*.rand),
        .binomial = Binomial(u32, f64).init(&rng_state.*.rand),
        .geometric = Geometric(u32, f64).init(&rng_state.*.rand),
        .multinomial = Multinomial(u32, f64).init(&rng_state.*.rand),
        .negative_binomial = NegativeBinomial(u32, f64).init(&rng_state.*.rand),
        .poisson = Poisson(u32, f64).init(&rng_state.*.rand),
        .uniform_int = UniformInt(i32).init(&rng_state.*.rand),
        .uniform_uint = UniformInt(u32).init(&rng_state.*.rand),

        .beta = Beta(f64).init(&rng_state.*.rand),
        .cauchy = Cauchy(f64).init(&rng_state.*.rand),
        .chi_squared = ChiSquared(u32, f64).init(&rng_state.*.rand),
        .dirichlet = Dirichlet(f64).init(&rng_state.*.rand),
        .exponential = Exponential(f64).init(&rng_state.*.rand),
        .gamma = Gamma(f64).init(&rng_state.*.rand),
        .normal = Normal(f64).init(&rng_state.*.rand),
        .uniform = Uniform(f64).init(&rng_state.*.rand),
    };
}

/// Deallocate the internally stored `RngState`.
pub fn deinit(self: *Self) void {
    self.allocator.destroy(self.rng_state);
}

/// Get a pointer to the internally stored random generator, `rand`.
pub fn getRand(self: Self) *Random {
    return &self.rng_state.*.rand;
}

pub fn rBernoulli(
    self: *Self,
    p: f64,
) u32 {
    return self.bernoulli.sample(p);
}

pub fn rBernoulliSlice(
    self: *Self,
    size: usize,
    p: f64,
) ![]u32 {
    return try self.bernoulli.sampleSlice(size, p, self.allocator);
}

pub fn rBinomial(
    self: *Self,
    n: u32,
    p: f64,
) u32 {
    return self.binomial.sample(n, p);
}

pub fn rBinomialSlice(
    self: *Self,
    size: usize,
    n: u32,
    p: f64,
) ![]u32 {
    return try self.binomial.sampleSlice(size, n, p, self.allocator);
}

pub fn dBinomial(
    self: *Self,
    k: u32,
    n: u32,
    p: f64,
    log: bool,
) f64 {
    if (log) {
        return self.binomial.lnPmf(k, n, p);
    }
    return self.binomial.pmf(k, n, p);
}

pub fn rGeometric(
    self: *Self,
    p: f64,
) u32 {
    return self.geometric.sample(p);
}

pub fn rGeometricSlice(
    self: *Self,
    size: usize,
    p: f64,
) ![]u32 {
    return try self.geometric.sampleSlice(size, p, self.allocator);
}

pub fn dGeometric(
    self: *Self,
    k: u32,
    p: f64,
    log: bool,
) f64 {
    if (log) {
        return self.geometric.lnPmf(k, p);
    }
    return self.geometric.pmf(k, p);
}

pub fn rMultinomial(
    self: *Self,
    n: u32,
    p_vec: []const f64,
) ![]u32 {
    const out_vec = try self.allocator.alloc(u32, p_vec.len);
    self.multinomial.sample(n, p_vec, out_vec);
    return out_vec;
}

pub fn rMultinomialSlice(
    self: *Self,
    size: usize,
    n: u32,
    p_vec: []const f64,
) ![]u32 {
    return try self.multinomial.sampleSlice(size, n, p_vec, self.allocator);
}

pub fn dMultinomial(
    self: *Self,
    k_vec: []const u32,
    p_vec: []const f64,
    log: bool,
) f64 {
    if (log) {
        return self.multinomial.lnPmf(k_vec, p_vec);
    }
    return self.multinomial.pmf(k_vec, p_vec);
}

pub fn rNegativeBinomial(
    self: *Self,
    n: u32,
    p: f64,
) u32 {
    return self.negative_binomial.sample(n, p);
}

pub fn rNegativeBinomialSlice(
    self: *Self,
    size: usize,
    n: u32,
    p: f64,
) ![]u32 {
    return try self.negative_binomial.sampleSlice(size, n, p, self.allocator);
}

pub fn dNegativeBinomial(
    self: *Self,
    k: u32,
    r: u32,
    p: f64,
    log: bool,
) f64 {
    if (log) {
        return self.negative_binomial.lnPmf(k, r, p);
    }
    return self.negative_binomial.pmf(k, r, p);
}

pub fn rPoisson(
    self: *Self,
    lambda: f64,
) u32 {
    return self.poisson.sample(lambda);
}

pub fn rPoissonSlice(
    self: *Self,
    size: usize,
    lambda: f64,
) ![]u32 {
    return try self.poisson.sampleSlice(size, lambda, self.allocator);
}

pub fn dPoisson(
    self: *Self,
    k: u32,
    lambda: f64,
    log: bool,
) f64 {
    if (log) {
        return self.poisson.lnPmf(k, lambda);
    }
    return self.poisson.pmf(k, lambda);
}

pub fn rUniformInt(self: *Self, low: i32, high: i32) i32 {
    return self.uniform_int.sample(low, high);
}

pub fn rUniformIntSlice(self: *Self, size: usize, low: i32, high: i32) ![]i32 {
    return try self.uniform_int.sampleSlice(
        size,
        low,
        high,
        self.allocator,
    );
}

pub fn rUniformUInt(self: *Self, low: u32, high: u32) u32 {
    return self.uniform_uint.sample(low, high);
}

pub fn rUniformUIntSlice(self: *Self, size: usize, low: u32, high: u32) ![]u32 {
    return try self.uniform_uint.sampleSlice(
        size,
        low,
        high,
        self.allocator,
    );
}

/// Generate a single sample from a slice of `items` with type `T`.
pub fn rSample(self: Self, comptime T: type, items: []const T) T {
    const idx = UniformInt(usize).init(
        &self.rng_state.*.rand,
    ).sample(
        0,
        items.len - 1,
    );
    return items[idx];
}

/// Generate `size` samples from a slice of `items` with type `T`.
/// Sampling is done with replacement.
pub fn rSampleSlice(
    self: Self,
    comptime T: type,
    size: usize,
    items: []const T,
    allocator: Allocator,
) ![]T {
    const idxs = UniformInt(usize).init(
        &self.rng_state.*.rand,
    ).sampleSlice(
        size,
        0,
        items.len - 1,
        allocator,
    );

    var res = try allocator.alloc(T, size);
    for (idxs, 0..) |idx, i| {
        res[i] = items[idx];
    }
    return res;
}

pub fn rWeightedSample(
    self: *Self,
    comptime T: type,
    items: []const T,
    weights: []const f64,
) T {
    var weighted = Weighted(T, f64).init(&self.rng_state.*.rand);
    return weighted.sample(items, weights);
}

pub fn rWeightedSampleSlice(
    self: *Self,
    comptime T: type,
    size: usize,
    items: []const T,
    weights: []const f64,
) ![]T {
    var weighted = Weighted(T, f64).init(&self.rng_state.*.rand);
    return try weighted.sampleSlice(size, items, weights, self.allocator);
}

pub fn rBeta(
    self: *Self,
    alpha: f64,
    beta: f64,
) f64 {
    return self.beta.sample(alpha, beta);
}

pub fn rBetaSlice(
    self: *Self,
    size: usize,
    alpha: f64,
    beta: f64,
) ![]f64 {
    return try self.beta.sampleSlice(size, alpha, beta, self.allocator);
}

pub fn dBeta(
    self: *Self,
    x: f64,
    alpha: f64,
    beta: f64,
    log: bool,
) !f64 {
    if (log) {
        return try self.beta.lnPdf(x, alpha, beta);
    }
    return try self.beta.pdf(x, alpha, beta);
}

pub fn rCauchy(
    self: Self,
    x0: f64,
    gamma: f64,
) f64 {
    return self.cauchy.sample(x0, gamma);
}

pub fn rCauchySlice(
    self: Self,
    size: usize,
    x0: f64,
    gamma: f64,
) ![]f64 {
    return try self.cauchy.sampleSlice(size, x0, gamma, self.allocator);
}

pub fn dCauchy(
    self: Self,
    x: f64,
    x0: f64,
    gamma: f64,
    log: bool,
) f64 {
    if (log) {
        return self.cauchy.lnPdf(x, x0, gamma);
    }
    return self.cauchy.pdf(x, x0, gamma);
}

pub fn rChiSquared(
    self: *Self,
    k: u32,
) f64 {
    return self.chi_squared.sample(k);
}

pub fn rChiSquaredSlice(
    self: *Self,
    size: usize,
    k: u32,
) ![]f64 {
    return try self.chi_squared.sampleSlice(size, k, self.allocator);
}

pub fn dChiSquared(
    self: *Self,
    x: f64,
    k: u32,
    log: bool,
) !f64 {
    if (log) {
        return try self.chi_squared.lnPdf(x, k);
    }
    return try self.chi_squared.pdf(x, k);
}

pub fn rDirichlet(
    self: *Self,
    alpha_vec: []const f64,
) ![]f64 {
    const out_vec = try self.allocator.alloc(f64, alpha_vec.len);
    self.dirichlet.sample(alpha_vec, out_vec);
    return out_vec;
}

pub fn rDirichletSlice(
    self: *Self,
    size: usize,
    alpha_vec: []const f64,
) ![]f64 {
    return try self.dirichlet.sampleSlice(size, alpha_vec, self.allocator);
}

pub fn dDirichlet(
    self: *Self,
    x_vec: []const f64,
    alpha_vec: []const f64,
    log: bool,
) !f64 {
    if (log) {
        return self.dirichlet.lnPdf(x_vec, alpha_vec);
    }
    return self.dirichlet.pdf(x_vec, alpha_vec);
}

pub fn rExponential(
    self: *Self,
    lambda: f64,
) f64 {
    return self.exponential.sample(lambda);
}

pub fn rExponentialSlice(
    self: *Self,
    size: usize,
    lambda: f64,
) ![]f64 {
    return try self.exponential.sampleSlice(size, lambda, self.allocator);
}

pub fn dExponential(
    self: *Self,
    x: f64,
    lambda: f64,
    log: bool,
) f64 {
    if (log) {
        return self.exponential.lnPdf(x, lambda);
    }
    return self.exponential.pdf(x, lambda);
}

pub fn rGamma(
    self: *Self,
    shape: f64,
    scale: f64,
) f64 {
    return self.gamma.sample(shape, scale);
}

pub fn rGammaSlice(
    self: *Self,
    size: usize,
    shape: f64,
    scale: f64,
) ![]f64 {
    return try self.gamma.sampleSlice(size, shape, scale, self.allocator);
}

pub fn dGamma(
    self: *Self,
    x: f64,
    shape: f64,
    scale: f64,
    log: bool,
) !f64 {
    if (log) {
        return try self.gamma.lnPdf(x, shape, scale);
    }
    return try self.gamma.pdf(x, shape, scale);
}

pub fn rNormal(
    self: *Self,
    mu: f64,
    sigma: f64,
) f64 {
    return self.normal.sample(mu, sigma);
}

pub fn rNormalSlice(
    self: *Self,
    size: usize,
    mu: f64,
    sigma: f64,
) ![]f64 {
    return try self.normal.sampleSlice(size, mu, sigma, self.allocator);
}

pub fn dNormal(
    self: *Self,
    x: f64,
    mu: f64,
    sigma: f64,
    log: bool,
) f64 {
    if (log) {
        return self.normal.lnPdf(x, mu, sigma);
    }
    return self.normal.pdf(x, mu, sigma);
}

pub fn rUniform(
    self: *Self,
    low: f64,
    high: f64,
) f64 {
    return self.uniform.sample(low, high);
}

pub fn rUniformSlice(
    self: *Self,
    size: usize,
    low: f64,
    high: f64,
) ![]f64 {
    return try self.uniform.sampleSlice(size, low, high, self.allocator);
}

test "Random Environment Creation" {
    const allocator = std.testing.allocator;
    var env = try Self.init(allocator);
    defer env.deinit();
    std.debug.print("\n{}\n", .{env.seed});

    std.debug.print("\n{any}\n", .{env.rng_state});

    // Bernoulli
    const bern = env.rBernoulli(0.1);
    std.debug.print("\nrBernoulli:\n{}\n", .{bern});

    const bern_slice = try env.rBernoulliSlice(10, 0.4);
    defer allocator.free(bern_slice);
    std.debug.print("\nrBernulliSlice:\n{any}\n", .{bern_slice});

    const val2 = env.dBinomial(8, 10, 0.75, false);
    std.debug.print("\n{}\n", .{val2});
}

test "Random Environment Creation w/ Seed" {
    const allocator = std.testing.allocator;
    var env = try Self.initWithSeed(2468, allocator);
    defer env.deinit();
    std.debug.print("\n{}\n", .{env.seed});

    std.debug.print("\n{any}\n", .{env.rng_state});

    const val = env.rGeometric(0.9);
    std.debug.print("\n{}\n", .{val});

    const val2 = env.dPoisson(10, 4.0, false);
    std.debug.print("\n{}\n", .{val2});
}

test "Sample Random Deviates" {
    std.debug.print("\n", .{});

    const allocator = std.testing.allocator;
    var env = try Self.init(allocator);
    defer env.deinit();

    const bern = env.rBernoulli(0.4);
    std.debug.print("\nBernoulli: {}\n", .{bern});

    const binom = env.rBinomial(10, 0.4);
    std.debug.print("Binomial: {}\n", .{binom});

    const geom = env.rGeometric(0.45);
    std.debug.print("Geometric: {}\n", .{geom});

    const mnm = try env.rMultinomial(10, &.{ 0.1, 0.3, 0.3, 0.2, 0.1 });
    defer allocator.free(mnm);
    std.debug.print("Multinomial: {any}\n", .{mnm});

    const nb = env.rNegativeBinomial(10, 0.4);
    std.debug.print("Negative Binomial: {}\n", .{nb});

    const pois = env.rPoisson(10.0);
    std.debug.print("Poisson: {}\n", .{pois});

    const unif_int = env.rUniformInt(-10, 20);
    std.debug.print("Uniform Int: {}\n", .{unif_int});

    const unif_uint = env.rUniformUInt(10, 20);
    std.debug.print("Uniform UInt: {}\n", .{unif_uint});

    const beta = env.rBeta(2.0, 5.0);
    std.debug.print("Beta: {}\n", .{beta});

    const cauchy = env.rCauchy(0.0, 2.0);
    std.debug.print("Cauchy: {}\n", .{cauchy});

    const chi_squared = env.rChiSquared(6);
    std.debug.print("Chi Squared: {}\n", .{chi_squared});

    const dirichlet = try env.rDirichlet(&.{ 0.1, 0.3, 0.3, 0.1 });
    defer allocator.free(dirichlet);
    std.debug.print("Dirichlet: {any}\n", .{dirichlet});

    const exp = env.rExponential(5.0);
    std.debug.print("Exponential: {}\n", .{exp});

    const gam = env.rGamma(2.0, 5.0);
    std.debug.print("Gamma: {}\n", .{gam});

    const norm = env.rNormal(10.0, 2.5);
    std.debug.print("Normal: {}\n", .{norm});

    const unif = env.rUniform(-2.0, 8.0);
    std.debug.print("Uniform: {}\n", .{unif});
}

test "Sample Random Slices" {
    std.debug.print("\n", .{});

    const allocator = std.testing.allocator;
    var env = try Self.init(allocator);
    defer env.deinit();

    const bern = try env.rBernoulliSlice(10, 0.4);
    defer allocator.free(bern);
    std.debug.print("\nBernoulli: {any}\n", .{bern});

    const binom = try env.rBinomialSlice(10, 10, 0.4);
    allocator.free(binom);
    std.debug.print("Binomial: {any}\n", .{binom});

    const geom = try env.rGeometricSlice(10, 0.45);
    defer allocator.free(geom);
    std.debug.print("Geometric: {any}\n", .{geom});

    const mnm = try env.rMultinomialSlice(10, 10, &.{ 0.1, 0.3, 0.3, 0.2, 0.1 });
    defer allocator.free(mnm);
    std.debug.print("Multinomial: {any}\n", .{mnm});

    const nb = try env.rNegativeBinomialSlice(10, 10, 0.4);
    defer allocator.free(nb);
    std.debug.print("Negative Binomial: {any}\n", .{nb});

    const pois = try env.rPoissonSlice(10, 10.0);
    defer allocator.free(pois);
    std.debug.print("Poisson: {any}\n", .{pois});

    const unif_int = try env.rUniformIntSlice(10, -10, 20);
    defer allocator.free(unif_int);
    std.debug.print("Uniform Int: {any}\n", .{unif_int});

    const unif_uint = try env.rUniformUIntSlice(10, 10, 20);
    defer allocator.free(unif_uint);
    std.debug.print("Uniform UInt: {any}\n", .{unif_uint});

    const beta = try env.rBetaSlice(10, 2.0, 5.0);
    defer allocator.free(beta);
    std.debug.print("Beta: {any}\n", .{beta});

    const cauchy = try env.rCauchySlice(10, 0.0, 2.0);
    defer allocator.free(cauchy);
    std.debug.print("Cauchy: {any}\n", .{cauchy});

    const chi_squared = try env.rChiSquaredSlice(10, 6);
    defer allocator.free(chi_squared);
    std.debug.print("Chi Squared: {any}\n", .{chi_squared});

    const dirichlet = try env.rDirichletSlice(10, &.{ 0.1, 0.3, 0.3, 0.1 });
    defer allocator.free(dirichlet);
    std.debug.print("Dirichlet: {any}\n", .{dirichlet});

    const exp = try env.rExponentialSlice(10, 5.0);
    defer allocator.free(exp);
    std.debug.print("Exponential: {any}\n", .{exp});

    const gam = try env.rGammaSlice(10, 2.0, 5.0);
    defer allocator.free(gam);
    std.debug.print("Gamma: {any}\n", .{gam});

    const norm = try env.rNormalSlice(10, 10.0, 2.5);
    defer allocator.free(norm);
    std.debug.print("Normal: {any}\n", .{norm});

    const unif = try env.rUniformSlice(10, -2.0, 8.0);
    defer allocator.free(unif);
    std.debug.print("Uniform: {any}\n", .{unif});
}

test "PMFs/PDFs" {
    std.debug.print("\n", .{});

    const allocator = std.testing.allocator;
    var env = try Self.init(allocator);
    defer env.deinit();

    try std.testing.expectApproxEqAbs(
        env.dBinomial(4, 10, 0.6, false),
        @exp(env.dBinomial(4, 10, 0.6, true)),
        1e-6,
    );

    try std.testing.expectApproxEqAbs(
        env.dGeometric(3, 0.2, false),
        @exp(env.dGeometric(3, 0.2, true)),
        1e-6,
    );

    try std.testing.expectApproxEqAbs(
        env.dMultinomial(&.{ 2, 3, 1 }, &.{ 0.25, 0.55, 0.2 }, false),
        @exp(env.dMultinomial(&.{ 2, 3, 1 }, &.{ 0.25, 0.55, 0.2 }, true)),
        1e-6,
    );

    try std.testing.expectApproxEqAbs(
        env.dNegativeBinomial(5, 2, 0.3, false),
        @exp(env.dNegativeBinomial(5, 2, 0.3, true)),
        1e-6,
    );

    try std.testing.expectApproxEqAbs(
        env.dPoisson(5, 10.0, false),
        @exp(env.dPoisson(5, 10.0, true)),
        1e-6,
    );

    const beta = try env.dBeta(0.2, 2.0, 4.0, false);
    const ln_beta = try env.dBeta(0.2, 2.0, 4.0, true);
    try std.testing.expectApproxEqAbs(beta, @exp(ln_beta), 1e-6);

    try std.testing.expectApproxEqAbs(
        env.dCauchy(2.0, 0.0, 1.5, false),
        @exp(env.dCauchy(2.0, 0.0, 1.5, true)),
        1e-6,
    );

    const chi_squared = try env.dChiSquared(2.0, 4, false);
    const ln_chi_squared = try env.dChiSquared(2.0, 4, true);
    try std.testing.expectApproxEqAbs(chi_squared, @exp(ln_chi_squared), 1e-6);

    const dirichlet = try env.dDirichlet(&.{ 0.2, 0.3, 0.1 }, &.{ 4.0, 6.0, 2.0 }, false);
    const ln_dirichlet = try env.dDirichlet(&.{ 0.2, 0.3, 0.1 }, &.{ 4.0, 6.0, 2.0 }, true);
    try std.testing.expectApproxEqAbs(dirichlet, @exp(ln_dirichlet), 1e-6);

    try std.testing.expectApproxEqRel(
        env.dExponential(5.0, 2.0, false),
        @exp(env.dExponential(5.0, 2.0, true)),
        1e-6,
    );

    const gamma = try env.dGamma(2.0, 5.0, 1.0, false);
    const ln_gamma = try env.dGamma(2.0, 5.0, 1.0, true);
    try std.testing.expectApproxEqAbs(gamma, @exp(ln_gamma), 1e-6);

    try std.testing.expectApproxEqAbs(
        env.dNormal(10.0, 8.0, 2.0, false),
        @exp(env.dNormal(10.0, 8.0, 2.0, true)),
        1e-6,
    );
}
