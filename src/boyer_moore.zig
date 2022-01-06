const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const testing = std.testing;

const test_suites = @import("test_cases.zig").test_suites;
const possibleValues = @import("common.zig").possibleValues;

pub fn StringFinder(comptime T: type) type {
    assert(std.meta.trait.isIndexable(T));
    const ElemType = std.meta.Elem(T);
    assert(@typeInfo(ElemType) == .Int);

    return struct {
        allocator: ?Allocator,
        pattern: T,
        bad_char: [possible_values]usize,
        good_suffix: []usize,

        const possible_values = possibleValues(ElemType);
        const Self = @This();

        /// An empty pattern, requires no allocations
        pub const empty = Self{
            .allocator = null,
            .pattern = "",
            .bad_char = [_]usize{0} ** possible_values,
            .good_suffix = &[_]usize{},
        };

        /// Returns the maximum length of suffixes of both strings
        fn longestCommonSuffix(a: T, b: T) usize {
            var i: usize = 0;
            while (i < a.len and i < b.len) : (i += 1) {
                if (a[(a.len - 1) - i] != b[(b.len - 1) - i]) {
                    break;
                }
            }
            return i;
        }

        /// Initializes a StringFinder with a pattern
        pub fn init(allocator: Allocator, pattern: T) !Self {
            if (pattern.len == 0) return Self.empty;

            var self = Self{
                .allocator = allocator,
                .pattern = pattern,
                .bad_char = undefined,
                .good_suffix = try allocator.alloc(usize, pattern.len),
            };

            const last = pattern.len - 1;

            // Initialize bad character rule table
            for (self.bad_char) |*x| x.* = pattern.len;

            for (pattern) |x, i| {
                if (i == last) break;
                self.bad_char[x] = last - i;
            }

            // Build good suffix rule table
            var last_prefix = last;

            // First pass
            {
                var i = last + 1;
                while (i > 0) : (i -= 1) {
                    if (std.mem.startsWith(ElemType, pattern, pattern[i..])) {
                        last_prefix = i;
                    }
                    self.good_suffix[i - 1] = last_prefix + last - (i - 1);
                }
            }

            // Second pass
            {
                var i: usize = 0;
                while (i < last) : (i += 1) {
                    const len_suffix = longestCommonSuffix(pattern, pattern[1 .. i + 1]);
                    if (pattern[i - len_suffix] != pattern[last - len_suffix]) {
                        self.good_suffix[last - len_suffix] = len_suffix + last - i;
                    }
                }
            }

            return self;
        }

        /// Frees all memory allocated by this string searcher
        pub fn deinit(self: *Self) void {
            if (self.allocator) |allocator| {
                allocator.free(self.good_suffix);
            }
        }

        /// Returns the index of the first occurence of the pattern in the
        /// text. Returns null if the pattern wasn't found
        pub fn next(self: Self, text: T) ?usize {
            var i: usize = self.pattern.len;
            while (i <= text.len) {
                // Try to match starting from the end of the pattern
                var j: usize = self.pattern.len;
                while (j > 0 and text[i - 1] == self.pattern[j - 1]) {
                    i -= 1;
                    j -= 1;
                }

                // If we matched until the beginning of the pattern, we
                // have a match
                if (j == 0) {
                    return i;
                }

                // Use the bad character table and the good suffix table
                // to advance our position
                i += std.math.max(
                    self.bad_char[text[i - 1]],
                    self.good_suffix[j - 1],
                );
            }

            return null;
        }
    };
}

test "boyer moore" {
    const allocator = testing.allocator;

    for (test_suites) |suite| {
        var sf = try StringFinder([]const u8).init(allocator, suite.pattern);
        defer sf.deinit();

        for (suite.cases) |case| {
            try testing.expectEqual(case.expected, sf.next(case.text));
        }
    }
}
