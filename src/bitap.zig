/// Bitap algorithm (exact matching variant)
///
/// See https://en.wikipedia.org/wiki/Bitap_algorithm for more details
const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

const test_suites = @import("test_cases.zig").test_suites;
const possibleValues = @import("common.zig").possibleValues;

pub fn bitap(
    comptime T: type,
    comptime max_pattern_length: comptime_int,
    text: T,
    pattern: T,
) ?usize {
    const ElemType = std.meta.Elem(T);
    assert(@typeInfo(ElemType) == .Int);
    assert(pattern.len <= max_pattern_length);

    const Int = std.meta.Int(.unsigned, max_pattern_length + 1);
    const Log2Int = std.meta.Int(.unsigned, std.math.log2(max_pattern_length + 1));
    const possible_values = possibleValues(ElemType);

    if (pattern.len == 0) return 0;
    const len = @as(Log2Int, @intCast(pattern.len));

    const one: Int = 1;

    var R: Int = ~one;
    var pattern_mask = [_]Int{std.math.maxInt(Int)} ** possible_values;

    for (pattern, 0..) |x, i| {
        pattern_mask[x] &= ~(one << @as(Log2Int, @intCast(i)));
    }

    for (text, 0..) |x, i| {
        R |= pattern_mask[x];
        R <<= 1;

        if ((R & (one << len)) == 0) {
            return if (i < len) 0 else i - len + 1;
        }
    }

    return null;
}

test "bitap" {
    inline for (&[_]comptime_int{ 31, 63, 127, 59, 67 }) |max_pattern_length| {
        for (test_suites) |suite| {
            for (suite.cases) |case| {
                try testing.expectEqual(case.expected, bitap(
                    []const u8,
                    max_pattern_length,
                    case.text,
                    suite.pattern,
                ));
            }
        }
    }
}
