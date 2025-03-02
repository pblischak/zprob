const std = @import("std");

/// Comptime check for integer types.
pub fn ensureIntegerType(comptime I: type) bool {
    return switch (@typeInfo(I)) {
        .ComptimeInt, .Int => true,
        else => @compileError("Comptime variable I must be an integer type"),
    };
}

/// Comptime check for float types.
pub fn ensureFloatType(comptime F: type) bool {
    if (F != f32 and F != f64) {
        @compileError("Only f32 and f64 float types are supported");
    }
    return switch (@typeInfo(F)) {
        .ComptimeFloat, .Float => true,
        else => @compileError("Comptime variable F must be a float type"),
    };
}

/// Check if values in slice add to 1.0, within tolerance `tol`.
pub fn sumToOne(comptime F: type, values: []const F, tol: F) bool {
    _ = ensureFloatType(F);
    var sum: F = 0.0;
    for (values) |v| {
        sum += v;
    }
    return std.math.approxEqRel(F, 1.0, sum, tol);
}
