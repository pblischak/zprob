/// Comptime check for integer types.
pub fn ensureIntegerType(comptime I: type) bool {
    return switch (@typeInfo(I)) {
        .ComptimeInt => true,
        .Int => true,
        else => @compileError("Comptime variable I must be an integer type"),
    };
}

/// Comptime check for float types.
pub fn ensureFloatType(comptime F: type) bool {
    return switch (@typeInfo(F)) {
        .ComptimeFloat => true,
        .Float => true,
        else => @compileError("Comptime variable F must be a float type"),
    };
}
