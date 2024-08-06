const std = @import("std");
const SSTable = @import("sstable.zig").SSTable;

pub fn compact(sstables: []SSTable) !SSTable {
    // Implement a merge algorithm to combine multiple SSTables into a single SSTable
    // For simplicity, assume all sstables are loaded in memory

    var merged_data = std.ArrayList([]const u8).init(std.heap.page_allocator);

    for (sstables) |sstable| {
        for (sstable.data) |item| {
            try merged_data.append(item);
        }
    }

    return SSTable{ .data = merged_data.toOwnedSlice() };
}
