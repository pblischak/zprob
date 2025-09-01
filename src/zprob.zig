//! ### zprob: A Zig Module for Random Number Distributions
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

pub const default_bernoulli = @import("bernoulli.zig").Bernoulli(u32, f64){};
pub const default_binomial = @import("binomial.zig").Binomial(u32, f64){};
pub const default_geometric = @import("geometric.zig").Geometric(u32, f64){};
pub const default_negative_binomial = @import("negative_binomial.zig").NegativeBinomial(u32, f64){};
pub const default_poisson = @import("poisson.zig").Poisson(u32, f64){};
pub const default_uniform_int = @import("uniform.zig").UniformInt(i32){};

// Continuous Probability Distributions
pub const Beta = @import("beta.zig").Beta;
pub const Cauchy = @import("cauchy.zig").Cauchy;
pub const ChiSquared = @import("chi_squared.zig").ChiSquared;
pub const Dirichlet = @import("dirichlet.zig").Dirichlet;
pub const Exponential = @import("exponential.zig").Exponential;
pub const Gamma = @import("gamma.zig").Gamma;
pub const Normal = @import("normal.zig").Normal;
pub const Uniform = @import("uniform.zig").Uniform;

pub const default_beta = @import("beta.zig").Beta(f64){};
pub const default_cauchy = @import("cauchy.zig").Cauchy(f64){};
pub const default_chi_squared = @import("chi_squared.zig").ChiSquared(u32, f64){};
pub const default_exponential = @import("exponential.zig").Exponential(f64){};
pub const default_gamma = @import("gamma.zig").Gamma(f64){};
pub const default_normal = @import("normal.zig").Normal(f64){};
pub const default_uniform = @import("uniform.zig").Uniform(f64){};

pub const special_functions = @import("special_functions.zig");
pub const utils = @import("utils.zig");

test {
    @import("std").testing.refAllDeclsRecursive(@This());
}
