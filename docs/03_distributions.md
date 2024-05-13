## Distributions API

### General design

```rs
const std = @import("std");
const zprob = @import("zprob");
const DefaultPrng = std.rand.DefaultPrng;

// Return type for `main` is either `void` or `!void` depending on if
// an error can be returned by any of the distribution's functions.
pub fn main() void {
    var prng = DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    var rand = prng.random();

    /*  !!! Distribution-specific code goes here !!! */
}
```

### Discrete distributions

#### Bernoulli

```rs
var bernoulli = zprob.Bernoulli(u32, f64).init(&rand);

_ = bernoulli.sample(0.4);
```

#### Binomial

```rs
var binomial = zprob.Binomial().init(&rand);

const val = binomial.sample(10, 0.25);
const val_slice = binomial.sampleSlice(100, 10, 0.25, allocator);
const prob = binomial.pmf(10, 4, 0.25);
const ln_prob = binomial.lnPmf(10, 4, 0.25);
```

#### Geometric

#### Multinomial

#### Negative Binomial

#### Poisson

### Continuous distributions

#### Beta

```rs
var beta = zprob.Beta(f64).init(&rand);
```

#### Chi-Squared

#### Dirichlet

#### Exponential

#### Gamma

#### Normal