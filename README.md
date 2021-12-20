# Zig-SimpleConf

Super simple config file parser for zig.

- Keys and values are separated by an equals sign `=`
- All keys and values are strings.
- Keys and values can contain spaces, although it's not recommended for keys
- Keys are everything on a line before the equals sign
- Values are everything after the equals sign to the end of the line
- Values can be empty
- Everything is allowed in the value except newlines
- All keys and values have leading and trailing whitespace trimmed
- Comments start with a hash character `#` and must be on their own line
- Lines with a value but no key result in an error
- Lines with a key but no equals result in an error

## Example config

```
# Comment
key = value
some_key = some value
```

# API

- The config key/value pairs are returned as a `BufMap`

```zig
/// Caller responsible for de-initializing returned BufMap.
/// Bytes are not kept in map.
fromBytes(allocator: *mem.Allocator, bytes: []const u8) !BufMap
```

```zig
/// Caller responsible for de-initializing returned BufMap
fromFile(allocator: *mem.Allocator, path: []const u8, max_bytes: usize) !BufMap
```
