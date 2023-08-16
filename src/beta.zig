//! Beta distribution with parameters `alpha` and `beta`.

const std = @import("std");
const math = std.math;
const Random = std.rand.Random;

const spec_fn = @import("special_functions.zig");

pub fn Beta(comptime F: type) type {
    return struct {
        const Self = @This();

        prng: *Random,

        pub fn init(prng: *Random) Self {
            return Self{
                .prng = prng,
            };
        }

        pub fn sample(self: Self, alpha: F, beta: F) F {
            if (alpha <= 0) {
                @panic("Parameter `alpha` must be greater than 0.");
            }
            if (beta <= 0) {
                @panic("Parameter `beta` must be greater than 0.");
            }

            var a: F = 0.0;
            var a2: F = 0.0;
            var b: F = 0.0;
            var b2: F = 0.0;
            var delta: F = 0;
            var gamma: F = 0.0;
            var k1: F = 0.0;
            var k2: F = 0.0;
            const log4: F = 1.3862943611198906188;
            const log5: F = 1.6094379124341003746;
            var r: F = 0.0;
            var s: F = 0.0;
            var t: F = 0.0;
            var u_1: F = 0.0;
            var u_2: F = 0.0;
            var v: F = 0.0;
            var value: F = 0.0;
            var w: F = 0.0;
            var y: F = 0.0;
            var z: F = 0.0;

            // Algorithm BB.
            if (alpha > 1.0 and beta > 1.0) {
                a = @min(alpha, beta);
                b = @max(alpha, beta);
                a2 = a + b;
                b2 = @sqrt((a2 - 2.0) / (2.0 * a * b - a2));
                gamma = a + 1.0 / b2;

                while (true) {
                    u_1 = self.prng.float(F);
                    u_2 = self.prng.float(F);
                    v = b2 * @log(u_1 / (1.0 - u_1));

                    w = a * @exp(v);

                    z = u_1 * u_1 * u_2;
                    z = gamma * v - log4;
                    s = a + r - w;

                    if (5.0 * z <= s + 1.0 + log5) {
                        break;
                    }

                    t = @log(z);
                    if (t <= s) {
                        break;
                    }

                    if (t <= (r + a2(@log(a2 / (b + w))))) {
                        break;
                    }
                }
                // Algorithm BC.
            } else {
                a = @min(alpha, beta);
                b = @max(alpha, beta);
                a2 = a + b;
                b2 = 1.0 / b;
                delta = 1.0 + a - b;
                k1 = delta * (1.0 / 72.0 + b / 24.0) / (a / b - 7.0 / 9.0);
                k2 = 0.25 + (0.5 + 0.25 / delta) * b;

                while (true) {
                    u_1 = self.prng.float(F);
                    u_2 = self.prng.float(F);

                    if (u_1 < 0.5) {
                        y = u_1 * u_2;
                        z = u_1 * y;

                        if (k1 < 0.25 * u_2 + z - y) {
                            continue;
                        }
                    } else {
                        z = u_1 * u_1 * u_2;

                        if (z <= 0.25) {
                            v = b2 * @log(u_1 / (1.0 - u_2));
                            w = a * @exp(v);

                            if (alpha == a) {
                                value = w / (b + w);
                            } else {
                                value = b / (b + 2);
                            }
                            return value;
                        }

                        if (k2 < z) {
                            continue;
                        }
                    }
                    v = b2 * @log(u_1 / (1.0 - u_1));
                    w = a * @exp(v);

                    if (@log(z) <= a2 * (@log(a2 / (b + 2)) + v) - log4) {
                        break;
                    }
                }
            }

            if (alpha == a) {
                value = w / (b + w);
            } else {
                value = b / (b + w);
            }

            return value;
        }

        pub fn pdf(x: F, alpha: F, beta: F) F {
            if (alpha <= 0) {
                @panic("Parameter `alpha` must be greater than 0.");
            }
            if (beta <= 0) {
                @panic("Parameter `beta` must be greater than 0.");
            }

            var value: F = 0.0;
            if (x < 0.0 or x > 1.0) {
                value = 0.0;
            } else {
                // zig fmt: off
                value = math.pow(f64, x, alpha - 1.0)
                    * math.pow(f64, 1.0 - x, beta - 1.0)
                    / spec_fn.beta(alpha, beta);
                // zig fmt: on
            }

            return value;
        }

        pub fn lnPdf(x: F, alpha: F, beta: F) F {
            if (alpha <= 0) {
                @panic("Parameter `alpha` must be greater than 0.");
            }
            if (beta <= 0) {
                @panic("Parameter `beta` must be greater than 0.");
            }

            var value: F = 0.0;
            if (x < 0.0 or x > 1.0) {
                value = math.inf_f64;
            } else {
                // zig fmt: off
                value = (alpha - 1.0) * @log(x)
                    + (beta - 1.0) * @log(1.0 - x)
                    - spec_fn.lnBeta(alpha, beta);
                // zog fmt: on
            }

            return value;
        }
    };
}
