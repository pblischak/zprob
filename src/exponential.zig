//! Exponential distribution with parameter `lambda`.

const std = @import("std");
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

pub fn exponentialSample(comptime F: type, lambda: F, rng: *Random) F {
    const l_f64: f64 = @floatCast(lambda);
    const value = -@log(1.0 - rng.float(f64)) / l_f64;
    switch (F) {
        f64 => return value,
        f32 => return @floatCast(value),
        else => @compileError("unknown floating point type"),
    }
}

pub fn exponentialPdf(comptime F: type, x: F, lambda: F) F {
    if (x < 0) {
        return 0.0;
    }
    const l_f64: f64 = @floatCast(lambda);
    const value = l_f64 * @exp(-l_f64 * x);

    switch (F) {
        f64 => return value,
        f32 => return @floatCast(value),
        else => @compileError("unknown floating point type"),
    }
}

pub fn exponentialLnPdf(comptime F: type, x: F, lambda: F) F {
    if (x < 0) {
        @panic("Cannot evaluate x less than 0.");
    }
    const l_f64: f64 = @floatCast(lambda);
    const value = -l_f64 * x * @log(l_f64) + 1.0;

    switch (F) {
        f64 => return value,
        f32 => return @floatCast(value),
        else => @compileError("unknown floating point type"),
    }
}
