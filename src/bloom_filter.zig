const std = @import("std");

const BloomFilter = struct {
    size: u64,
    hash_count: u64,
    bit_array: []u8,
    allocator: std.mem.Allocator,

    pub fn init(size: u64, hash_count: u64, allocator: std.mem.Allocator) !BloomFilter {
        const bit_array = try allocator.alloc(u8, size);
        @memset(bit_array, 0);
        return BloomFilter{ 
          .size = size, 
          .hash_count = hash_count, 
          .bit_array = bit_array,
          .allocator = allocator
          };
    }

    fn fnv1a_hash(self: *BloomFilter, data: []const u8) u64 {
        _ = self;
        var hash: u64 = 14695981039346656037;
        for (data) |byte| {
            hash ^= byte;
            hash *%= 1099511628211;
        }
        return hash;
    }

    fn djb2_hash(self: *BloomFilter, data: []const u8) u64 {
        _ = self;

        var hash: u64 = 5381;
        for (data) |byte| {
            hash = ((hash << 5) + hash) + byte;
        }
        return hash;
    }

    fn hashes(self: *BloomFilter, item: []const u8) ![]u64 {
        const hash1 = self.fnv1a_hash(item);
        const hash2 = self.djb2_hash(item);

        var result = try self.allocator.alloc(usize, self.hash_count);
        for (0..self.hash_count) |i| {
            result[i] = (hash1 + i * hash2) % self.size;
        }
        return result;
    }

    pub fn add(self: *BloomFilter, item: []const u8) !void {
        const _hashes = try self.hashes(item);
        defer self.allocator.free(_hashes);
        for (0.._hashes.len) |hash| {
            self.bit_array[hash] = 1;
        }
    }

    pub fn check(self: *BloomFilter, item: []const u8) !bool {
        const _hashes = try self.hashes(item);
        defer self.allocator.free(hashes);
        for (0.._hashes.len) |hash| {
            if (self.bit_array[hash] == 0) {
                return false;
            }
        }
        return true;
    }

    pub fn deinit(self: *BloomFilter) void {
        self.allocator.free(self.bit_array);
    }
};

test "bloom" {
    const allocator = std.testing.allocator;

    var bloom = try BloomFilter.init(1000, 5, allocator);
    defer bloom.deinit();
    // Adding items
    try bloom.add("apple");
    try bloom.add("banana");

    // Checking membership
    std.debug.print("apple: {}\n", .{try bloom.check("apple")}); // true
    std.debug.print("banana: {}\n", .{try bloom.check("banana")}); // true
    std.debug.print("cherry: {}\n", .{try bloom.check("cherry")}); // false
}
