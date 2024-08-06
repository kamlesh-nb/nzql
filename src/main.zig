const std = @import("std");
const BloomFilter = @import("bloom_filter.zig").BloomFilter;
pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var bloom = try BloomFilter.init(allocator, 1000, 5);
    defer bloom.deinit();
    // Adding items
    try bloom.add("apple");
    try bloom.add("banana");

    // Checking membership
    std.debug.print("apple: {}\n", .{try bloom.check("apple")}); // true
    std.debug.print("banana: {}\n", .{try bloom.check("banana")}); // true
    std.debug.print("cherry: {}\n", .{try bloom.check("cherry")}); // false
}
 