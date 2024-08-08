const std = @import("std");

pub const BloomFilter = struct {
    size: u64,
    hash_count: u64,
    bit_array: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, size: u64, hash_count: u64) !BloomFilter {
        const bit_array = try allocator.alloc(u8, size);
        @memset(bit_array, 0);
        return BloomFilter{ .size = size, .hash_count = hash_count, .bit_array = bit_array, .allocator = allocator };
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

        var result = try self.allocator.alloc(u64, self.hash_count);
        for (0..self.hash_count) |i| {
            result[i] = (hash1 + i * hash2) % self.size;
        }
        return result;
    }

    pub fn add(self: *BloomFilter, item: []const u8) !void {
        const _hashes = try self.hashes(item);
        defer self.allocator.free(_hashes);
        for (0..self.hash_count) |hash| {
            self.bit_array[_hashes[hash]] = 1;
        }
    }

    pub fn check(self: *BloomFilter, item: []const u8) !bool {
        const _hashes = try self.hashes(item);
        defer self.allocator.free(_hashes);
        for (0..self.hash_count) |hash| {
            if (self.bit_array[_hashes[hash]] == 0) {
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

    var bloom = try BloomFilter.init(allocator, 1000, 5);
    defer bloom.deinit();
    // Adding items
    try bloom.add("apple");
    try bloom.add("banana");

    // Checking membership
    std.debug.print("\napple: {}\n", .{try bloom.check("apple")}); // true
    std.debug.print("banana: {}\n", .{try bloom.check("banana")}); // true
    std.debug.print("cherry: {}\n", .{try bloom.check("cherry")}); // false
}

test "has-test" {
    const allocator = std.testing.allocator;

    var bloom = try BloomFilter.init(allocator, 1000, 5);
    defer bloom.deinit();

    const d = bloom.fnv1a_hash("a27ac50274524eaa");
    std.debug.print("\n{d}\n", .{d});
}

//2998916403606747793
//2998916403606747793
//4378059445348249422
//13476040837531404128
