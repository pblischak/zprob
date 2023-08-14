//! zprob: A Zig Library for Probability Distributions

/// Discrete Probability Distributions
pub const Bernoulli = @import("bernoulli.zig").Bernoulli;
pub const Binomial = @import("binomial.zig").Binomial;
pub const Geometric = @import("geometric.zig").Geometric;
pub const Multinomial = @import("multinomial.zig").Multinomial;
pub const NegativeBinomial = @import("negative_binomial.zig").NegativeBinomial;
pub const Poisson = @import("poisson.zig").Poisson;

/// Continuous Probability Distributions
pub usingnamespace @import("beta.zig");
pub usingnamespace @import("chi_squared.zig");
pub usingnamespace @import("dirichlet.zig");
pub usingnamespace @import("exponential.zig");
pub const Gamma = @import("gamma.zig").Gamma;
pub usingnamespace @import("multivariate_normal.zig");
pub usingnamespace @import("normal.zig");

/// Special Functions
pub usingnamespace @import("special_functions.zig");
