//! zprob: A Zig Library for Probability Distributions

/// Discrete Probability Distributions
pub const Bernoulli = @import("bernoulli.zig").Bernoulli;
pub const Binomial = @import("binomial.zig").Binomial;
pub const Geometric = @import("geometric.zig").Geometric;
pub const Multinomial = @import("multinomial.zig").Multinomial;
pub const NegativeBinomial = @import("negative_binomial.zig").NegativeBinomial;
pub const Poisson = @import("poisson.zig").Poisson;

/// Continuous Probability Distributions
pub const Beta = @import("beta.zig").Beta;
pub const ChiSquared = @import("chi_squared.zig").ChiSquared;
pub const Dirichlet = @import("dirichlet.zig").Dirichlet;
pub const Exponential = @import("exponential.zig").Exponential;
pub const Gamma = @import("gamma.zig").Gamma;
pub const MultivariateNormal = @import("multivariate_normal.zig").MultivariateNormal;
pub const Normal = @import("normal.zig").Normal;
