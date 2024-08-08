const std = @import("std");

const Entry = struct {
    key: ?[]const u8,
    value: ?[]const u8,
};

const HashMapError = error{
    InitializeError,
    ResizeError,
    PutError,
    GetError,
};

const HashMap = struct {
    allocator: *std.mem.Allocator,
    capacity: usize,
    size: usize,
    data: []Entry,

    pub fn init(allocator: *std.mem.Allocator, initial_capacity: usize) !HashMap {
        const map = HashMap{
            .allocator = allocator,
            .capacity = initial_capacity,
            .size = 0,
            .data = try allocator.alloc(Entry, initial_capacity),
        };
        for (map.data) |*entry| {
            entry.key = null;
            entry.value = null;
        }
        return map;
    }

    pub fn deinit(self: *HashMap) void {
        self.allocator.free(self.data);
    }

    pub fn hash(self: *HashMap, key: []const u8) u64 {
        _ = self;
        var _hash: u64 = 14695981039346656037;
        for (key) |byte| {
            _hash ^= byte;
            _hash *%= 1099511628211;
        }
        return _hash;
    }

    fn find_slot(self: *HashMap, key: []const u8) usize {
        const _hash = self.hash(key);
        var index = _hash % self.capacity;
        if (self.data[index].key) |k| {
            while (k.len > 0 and !std.mem.eql(u8, k, key)) {
                index = (index + 1) % self.capacity;
            }
        }
        return index;
    }

    fn resize(self: *HashMap, new_capacity: usize) HashMapError!void {
        const new_data = self.allocator.alloc(Entry, new_capacity) catch |e| {
            std.debug.print("Alloc Error: {any}\n", .{e});
            return;
        };
        for (new_data) |*entry| {
            entry.key = null;
            entry.value = null;
        }

        const old_data = self.data;
        // const old_capacity = self.capacity;

        self.data = new_data;
        self.capacity = new_capacity;
        self.size = 0;

        for (old_data) |entry| {
            if (entry.key != null) {
                self.put(entry.key.?, entry.value.?) catch |e| {
                    std.debug.print("Put Error: {any}\n", .{e});
                    return;
                };
            }
        }

        self.allocator.free(old_data);
    }

    pub fn put(self: *HashMap, key: []const u8, value: []const u8) !void {
        if (self.size + 1 > self.capacity / 2) {
            self.resize(self.capacity * 2) catch |e| {
                std.debug.print("Resize Error: {any}\n", .{e});
            };
        }

        const index = self.find_slot(key);
        if (self.data[index].key == null) {
            self.size += 1;
        }

        self.data[index].key = key;
        self.data[index].value = value;
    }

    pub fn get(self: *HashMap, key: []const u8) ?[]const u8 {
        const index = self.find_slot(key);
        if (self.data[index].key != null) {
            return self.data[index].value;
        } else {
            return null;
        }
    }
};

test "hash-map" {
    var allocator = std.testing.allocator;

    var map = try HashMap.init(&allocator, 16);
    defer map.deinit();

    try map.put("key1", "value1");
    try map.put("key2", "value2");

    const value1 = map.get("key1");
    if (value1 != null) {
        std.debug.print("Found: {any}\n", .{value1});
    } else {
        std.debug.print("Not Found\n", .{});
    }

    const value2 = map.get("key2");
    if (value2 != null) {
        std.debug.print("Found: {any}\n", .{value2});
    } else {
        std.debug.print("Not Found\n", .{});
    }
}
