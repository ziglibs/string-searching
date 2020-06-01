pub const Testcase = struct {
    text: []const u8,
    expected: ?usize,
};

pub const Testsuite = struct {
    pattern: []const u8,
    cases: []const Testcase,
};

pub const test_suites = [_]Testsuite{
    Testsuite{
        .pattern = "",
        .cases = &[_]Testcase{
            .{ .text = "zig", .expected = 0 },
            .{ .text = "", .expected = 0 },
            .{ .text = "a", .expected = 0 },
            .{ .text = "lang", .expected = 0 },
        },
    },
    Testsuite{
        .pattern = "a",
        .cases = &[_]Testcase{
            .{ .text = "zig", .expected = null },
            .{ .text = "", .expected = null },
            .{ .text = "a", .expected = 0 },
            .{ .text = "lang", .expected = 1 },
        },
    },
    Testsuite{
        .pattern = "zig",
        .cases = &[_]Testcase{
            .{ .text = "zig", .expected = 0 },
            .{ .text = "ziglang", .expected = 0 },
            .{ .text = "langzig", .expected = 4 },
            .{ .text = "langziglang", .expected = 4 },
            .{ .text = "", .expected = null },
            .{ .text = "firefox", .expected = null },
            .{ .text = "abc abc ziglang", .expected = 8 },
        },
    },
};
