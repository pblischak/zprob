//! zprob: A Zig Library for Probability Distributions

/// Discrete Probability Distributions
pub const Bernoulli = @import("bernoulli.zig").Bernoulli;
pub usingnamespace @import("binomial.zig");
pub usingnamespace @import("geometric.zig");
pub usingnamespace @import("multinomial.zig");
pub usingnamespace @import("negative_binomial.zig");
pub usingnamespace @import("poisson.zig");

/// Continuous Probability Distributions
pub usingnamespace @import("beta.zig");
pub usingnamespace @import("chi_squared.zig");
pub usingnamespace @import("dirichlet.zig");
pub usingnamespace @import("exponential.zig");
pub usingnamespace @import("gamma.zig");
pub usingnamespace @import("multivariate_normal.zig");
pub usingnamespace @import("normal.zig");

/// Special Functions
pub usingnamespace @import("special_functions.zig");
