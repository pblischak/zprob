//! Exponential distribution with parameter `lambda`.

const std = @import("std");
const Random = std.rand.Random;

pub fn Exponential(comptime F: type) type {
    return struct {
        const Self = @This();

        prng: *Random,

        pub fn init(prng: *Random) Self {
            return Self{
                .prng = prng,
            };
        }

        pub fn sample(self: Self, lambda: F) F {
            const value = -@log(1.0 - self.prng.float(F)) / lambda;
            return value;
        }

        pub fn pdf(x: F, lambda: F) F {
            if (x < 0) {
                return 0.0;
            }
            const value = lambda * @exp(-lambda * x);
            return value;
        }

        pub fn lnPdf(x: F, lambda: F) F {
            if (x < 0) {
                @panic("Cannot evaluate x less than 0.");
            }
            const value = -lambda * x * @log(lambda) + 1.0;
            return value;
        }
    };
}
