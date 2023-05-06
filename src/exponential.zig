//! Exponential distribution with parameter `lambda`.

const std = @import("std");
const Random = std.rand.Random;
const DefaultPrng = std.rand.Xoshiro256;

pub fn exponentialSample(comptime T: type, lambda: T, rng: *Random) T {
    const l_f64 = @floatCast(f64, lambda);
    const value = -@log(1.0 - rng.float(f64)) / l_f64;
    switch (T) {
        f64 => return value,
        f32 => return @floatCast(f32, value),
        else => @compileError("unknown floating point type"),
    }
}

pub fn exponentialPdf(comptime T: type, lambda: T, x: T) T {
    if (x < 0) {
        return 0.0;
    }
    const l_f64 = @floatCast(f64, lambda);
    const value = l_f64 * @exp(-l_f64 * x);

    switch (T) {
        f64 => return value,
        f32 => return @floatCast(f32, value),
        else => @compileError("unknown floating point type"),
    }
}

pub fn exponentialLnPdf(comptime T: type, lambda: T, x: T) T {
    if (x < 0) {
        @panic("Cannot evaluate x less than 0.");
    }
    const l_f64 = @floatCast(f64, lambda);
    const value = -l_f64 * x * @log(l_f64) + 1.0;

    switch (T) {
        f64 => return value,
        f32 => return @floatCast(f32, value),
        else => @compileError("unknown floating point type"),
    }
}
