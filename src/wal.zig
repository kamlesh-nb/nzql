const std = @import("std");

pub const WAL = struct {
    file: std.fs.File,

    pub fn init(file_path: []const u8) !WAL {
        const file = try std.fs.cwd().createFile(file_path, .{ .append = true });
        return WAL{ .file = file };
    }

    pub fn log(self: *WAL, key: []const u8, value: []const u8) !void {
        try self.file.writeAll(key);
        try self.file.writeAll(value);
        try self.file.writeAll("\n");
    }
};
