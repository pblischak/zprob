const std = @import("std");

/// Comptime check for integer types.
pub fn ensureIntegerType(comptime I: type) bool {
    return switch (@typeInfo(I)) {
        .comptime_int, .int => true,
        else => @compileError("Comptime variable I must be an integer type"),
    };
}

/// Comptime check for float types.
pub fn ensureFloatType(comptime F: type) bool {
    if (F == f16) {
        @compileError("Float type f16 not supported");
    }
    return switch (@typeInfo(F)) {
        .comptime_float, .float => true,
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
