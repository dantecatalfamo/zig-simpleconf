const std = @import("std");
const ascii = std.ascii;
const BufMap = std.BufMap;
const debug = std.debug;
const mem = std.mem;
const testing = std.testing;

/// Caller responsible for de-initializing returned BufMap.
/// Bytes are not kept in map.
pub fn fromBytes(allocator: mem.Allocator, bytes: []const u8) !BufMap {
    var map = BufMap.init(allocator);
    errdefer map.deinit();
    var lines = mem.split(u8, bytes, "\n");
    while (lines.next()) |line| {
        var key_begin: u32 = 0;
        var key_end: u32 = 0;
        var value_begin: u32 = 0;
        var split_location: u32 = 0;
        var key: []const u8 = undefined;
        var value: []const u8 = undefined;

        if (line.len == 0) { continue; }

        while (key_begin < line.len and ascii.isBlank(line[key_begin])) : (key_begin += 1) {}
        if (key_begin == line.len or line[key_begin] == '#') { continue; }

        if (line[key_begin] == '=') {
            return error.MissingKey;
        }

        split_location = key_begin;
        while (split_location < line.len and line[split_location] != '=') : (split_location += 1) {}
        if (split_location == line.len) {
            return error.MissingValue;
        }

        key_end = split_location - 1;
        while (key_begin < key_end and ascii.isBlank(line[key_end])) : (key_end -= 1) {}
        key_end += 1;

        key = line[key_begin..key_end];

        value_begin = split_location + 1;
        while (value_begin < line.len and ascii.isBlank(line[value_begin])) : (value_begin += 1) {}
        value = line[value_begin..];

        try map.put(key, value);
    }
    return map;
}

/// Caller responsible for de-initializing returned BufMap
pub fn fromFile(allocator: mem.Allocator, path: []const u8, max_bytes: usize) !BufMap {
    var map = BufMap.init(allocator);
    errdefer map.deinit();
    var file_bytes = try std.fs.cwd().readFileAlloc(allocator, path, max_bytes);
    defer allocator.free(file_bytes);
    return try fromBytes(allocator, file_bytes);
}

test "fromBytes parses correctly" {
    const conf =
        \\ thing1=banana and all that
        \\ thing2=orange
        \\ # this is a comment
        \\ thing3=pear
        \\       lots of spaces=wowza that's a lot
        \\
        \\ space between  =  the equals
        \\ no value=
    ;
    var map = try fromBytes(testing.allocator, conf);
    defer map.deinit();

    try testing.expectEqualStrings(map.get("thing1").?, "banana and all that");
    try testing.expectEqualStrings(map.get("thing2").?, "orange");
    try testing.expectEqualStrings(map.get("thing3").?, "pear");
    try testing.expectEqualStrings(map.get("space between").?, "the equals");
    try testing.expectEqualStrings(map.get("no value").?, "");

    const missing_key =
        \\ valid = good
        \\    = missing key
    ;
    var key_error_map = fromBytes(testing.allocator, missing_key);
    try testing.expectError(error.MissingKey, key_error_map);

    const missing_value = "  nothing\n      \n";
    var value_missing_map = fromBytes(testing.allocator, missing_value);
    try testing.expectError(error.MissingValue, value_missing_map);
}

test "fromFile doesn't leak" {
    var map = try fromFile(testing.allocator, "../test/test.conf", 1024 * 1024);
    defer map.deinit();
}
