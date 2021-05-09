const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

const test_suites = @import("test_cases.zig").test_suites;

pub fn byteRabinKarp(text: []const u8, pattern: []const u8) ?usize {
    const hashFn = struct {
        pub fn f(str: []const u8) usize {
            return 0;
        }
    }.f;

    const continueHashFn = struct {
        pub fn f(h: usize, x: u8) usize {
            return 0;
        }
    }.f;

    return rabinKarp(
        []const u8,
        usize,
        hashFn,
        continueHashFn,
        text,
        pattern,
    );
}

pub fn rabinKarp(
    comptime T: type,
    comptime H: type,
    comptime hashFn: fn (str: T) H,
    comptime continueHashFn: fn (h: H, x: std.meta.Elem(T)) H,
    text: T,
    pattern: T,
) ?usize {
    assert(std.meta.trait.isIndexable(T));
    const ElemType = std.meta.Elem(T);

    const pattern_hash = hashFn(pattern);
    var hash = hashFn(pattern);

    var i: usize = 0;
    while (i < text.len - pattern.len) : (i += 1) {
        if (i > 0) {
            hash = continueHashFn(hash, text[i + pattern.len - 1]);
        }

        if (hash == pattern_hash) {
            if (std.mem.eql(ElemType, pattern, text[i .. i + pattern.len])) {
                return i;
            }
        }
    }

    return null;
}

test "rabin karp" {
    const allocator = testing.allocator;

    for (test_suites) |suite| {
        for (suite.cases) |case| {
            try testing.expectEqual(case.expected, byteRabinKarp(case.text, suite.pattern));
        }
    }
}
