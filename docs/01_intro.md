## Intro

The `zprob` module provides functionality for random number generation for
applications in statistics, probability, data science, or just anywhere you need to randomly sample
from a collection (like an `ArrayList`). The easiest way to get started with
`zprob` is to read through the brief guide that is part of these docs. This guide
demonstrates the high-level API that `zprob` exposes through its `RandomEnvironment`
struct, 

**Acknowledgements**

`zprob` was largely inspired by the following projects:

  - [GNU Scientific Library](https://github.com/ampl/gsl/tree/master/randist)
  - [`rand_distr`](https://github.com/rust-random/rand/tree/master/rand_distr) Rust crate
  - [`RANLIB`](https://people.sc.fsu.edu/~jburkardt/c_src/ranlib/ranlib.html) C library