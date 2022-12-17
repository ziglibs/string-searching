const std = @import("std");

pub const bitap = @import("bitap.zig");
pub const boyer_moore = @import("boyer_moore.zig");

test {
    std.testing.refAllDeclsRecursive(@This());
}
