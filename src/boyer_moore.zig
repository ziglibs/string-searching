const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

/// Returns the maximum length of suffixes of both strings
fn longestCommonSuffix(a: []const u8, b: []const u8) usize {
    var i: usize = 0;
    while (i < a.len and i < b.len) : (i += 1) {
        if (a[(a.len - 1) - i] != b[(b.len - 1) - i]) {
            break;
        }
    }
    return i;
}

pub const StringFinder = struct {
    allocator: ?*Allocator,
    pattern: []const u8,
    bad_char: [possible_values]usize,
    good_suffix: []usize,

    const possible_values = std.math.maxInt(u8) + 1;
    const Self = @This();

    /// An empty pattern, requires no allocations
    pub const empty = Self{
        .allocator = null,
        .pattern = "",
        .bad_char = [_]usize{0} ** possible_values,
        .good_suffix = &[_]usize{},
    };

    /// Initializes a StringFinder with a pattern
    pub fn init(allocator: *Allocator, pattern: []const u8) !Self {
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
                if (std.mem.startsWith(u8, pattern, pattern[i..])) {
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
    pub fn next(self: Self, text: []const u8) ?usize {
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

test "empty pattern" {
    const allocator = testing.allocator;

    var sf = try StringFinder.init(allocator, "");
    defer sf.deinit();

    testing.expectEqual(@as(?usize, 0), sf.next("zig"));
    testing.expectEqual(@as(?usize, 0), sf.next(""));
    testing.expectEqual(@as(?usize, 0), sf.next("a"));
    testing.expectEqual(@as(?usize, 0), sf.next("lang"));
}

test "pattern with length 1" {
    const allocator = testing.allocator;

    var sf = try StringFinder.init(allocator, "a");
    defer sf.deinit();

    testing.expectEqual(@as(?usize, null), sf.next("zig"));
    testing.expectEqual(@as(?usize, null), sf.next(""));
    testing.expectEqual(@as(?usize, 0), sf.next("a"));
    testing.expectEqual(@as(?usize, 1), sf.next("lang"));
}

test "test matching" {
    const allocator = testing.allocator;

    var sf = try StringFinder.init(allocator, "zig");
    defer sf.deinit();

    testing.expectEqual(@as(?usize, 0), sf.next("zig"));
    testing.expectEqual(@as(?usize, 0), sf.next("ziglang"));
    testing.expectEqual(@as(?usize, 4), sf.next("langzig"));
    testing.expectEqual(@as(?usize, 4), sf.next("langziglang"));
    testing.expectEqual(@as(?usize, null), sf.next(""));
    testing.expectEqual(@as(?usize, null), sf.next("firefox"));
    testing.expectEqual(@as(?usize, 8), sf.next("abc abc ziglang"));
}
