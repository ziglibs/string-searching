const std = @import("std");

/// Returns the number of possible values for an integer type
pub fn possibleValues(comptime Type: type) comptime_int {
    return std.math.maxInt(Type) - std.math.minInt(Type) + 1;
}
