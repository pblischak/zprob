//! zprob: A Zig Module for Probability Distributions
//!
//! For each distribution, the following conditions are checked (when relevant) at compile time:
//! - `comptime` parameter `I` should be an integer type.
//! - `comptime` parameter `F` should be a float type.

pub const RandomEnvironment = @import("RandomEnvironment.zig");

// Discrete Probability Distributions
pub const Bernoulli = @import("bernoulli.zig").Bernoulli;
pub const Binomial = @import("binomial.zig").Binomial;
pub const Geometric = @import("geometric.zig").Geometric;
pub const Multinomial = @import("multinomial.zig").Multinomial;
pub const NegativeBinomial = @import("negative_binomial.zig").NegativeBinomial;
pub const Poisson = @import("poisson.zig").Poisson;
pub const UniformInt = @import("uniform.zig").UniformInt;
pub const Weighted = @import("sample.zig").Weighted;

// Continuous Probability Distributions
pub const Beta = @import("beta.zig").Beta;
pub const Cauchy = @import("cauchy.zig").Cauchy;
pub const ChiSquared = @import("chi_squared.zig").ChiSquared;
pub const Dirichlet = @import("dirichlet.zig").Dirichlet;
pub const Exponential = @import("exponential.zig").Exponential;
pub const Gamma = @import("gamma.zig").Gamma;
pub const Normal = @import("normal.zig").Normal;
pub const Uniform = @import("uniform.zig").Uniform;

pub const special_functions = @import("special_functions.zig");
pub const utils = @import("utils.zig");

test {
    @import("std").testing.refAllDeclsRecursive(@This());
}
