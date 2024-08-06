const std = @import("std");
const MemTable = @import("memtable.zig").MemTable;
const WAL = @import("wal.zig").WAL;
const SSTable = @import("sstable.zig").SSTable;

pub const DB = struct {
    memtable: MemTable,
    wal: WAL,
    sstables: []SSTable,

    pub fn init(allocator: *std.mem.Allocator, wal_path: []const u8) !DB {
        return DB{
            .memtable = MemTable.init(allocator),
            .wal = try WAL.init(wal_path),
            .sstables = &[_]SSTable{},
        };
    }

    pub fn put(self: *DB, key: []const u8, value: []const u8) !void {
        try self.wal.log(key, value);
        try self.memtable.put(key, value);
        // Check if memtable needs to be flushed
        // if self.memtable.size() > threshold {
        //     self.flush() catch {};
        // }
    }

    pub fn get(self: *const DB, key: []const u8) ?[]const u8 {
        var value = self.memtable.get(key);
        if (value) |v| {
            return v;
        }

        // Check SSTables
        for (self.sstables) |sstable| {
            value = sstable.get(key);
            if (value) |v| {
                return v;
            }
        }

        return null;
    }

    fn flush(self: *DB) !void {
        // Write memtable to SSTable and reset memtable
        const sstable_data = self.memtable.toSSTableData();
        const sstable = try SSTable.create(sstable_data);
        try self.sstables.append(sstable);
        self.memtable.reset();
    }
};

test "db" {
    const allocator = std.testing.allocator;
    var db = try DB.init(allocator, "wal.log");

    try db.put("key1", "value1");
    const value = db.get("key1");
    std.debug.print("Retrieved value: {}\n", .{value orelse "not found"});
}
