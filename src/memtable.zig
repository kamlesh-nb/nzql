const std = @import("std");

pub const MemTable = struct {
    // Define your data structure, e.g., Red-Black tree
    // For simplicity, let's use a Zig sorted map (use a more efficient structure for production)
    table: std.AutoHashMap([]const u8, []const u8),

    pub fn init(allocator: *std.mem.Allocator) MemTable {
        return MemTable{
            .table = std.AutoHashMap([]const u8, []const u8).init(allocator),
        };
    }

    pub fn put(self: *MemTable, key: []const u8, value: []const u8) !void {
        self.table.put(key, value) catch |err| {
            std.debug.print("Error inserting into MemTable: {}\n", .{err});
            return err;
        };
    }

    pub fn get(self: *const MemTable, key: []const u8) ?[]const u8 {
        return self.table.get(key);
    }
};
