const std = @import("std");

const BsonTypes = enum(u8) {
    Double = 0x01,
    String = 0x02,
    Bool = 0x08,
    Int32 = 0x10,
    Int64 = 0x12,
    UInt64 = 0x11,
    Decimal = 0x13,
};

const Bson = @This();

buffer: []u8,
length: usize = 4,
capacity: usize,
pos: usize = 0,
allocator: *std.mem.Allocator,

pub fn init(allocator: *std.mem.Allocator, initial_capacity: usize) !Bson {
    return Bson{
        .buffer = try allocator.alloc(u8, initial_capacity),
        .capacity = initial_capacity,
        .allocator = allocator,
    };
}

pub fn deinit(self: *Bson) void {
    self.allocator.free(self.buffer);
}

fn resize(self: *Bson, new_capacity: usize) !void {
    self.buffer = try self.allocator.realloc(self.buffer, new_capacity);
    self.capacity = new_capacity;
}

fn putBytes(self: *Bson, data: []const u8) !void {
    if (self.length + data.len > self.capacity) {
        const new_capacity = @max(self.capacity * 2, self.length + data.len);
        try self.resize(new_capacity);
    }
    const endIndex = self.length + data.len;
    @memcpy(self.buffer[self.length..endIndex], data[0..data.len]);
    self.length += data.len;
}

fn putFromFile(self: *Bson, bytes: []u8) !void {
    self.length = 0;
    if (self.length + bytes.len > self.capacity) {
        const new_capacity = @max(self.capacity * 2, self.length + bytes.len);
        try self.resize(new_capacity);
    }
    @memcpy(self.buffer[0..bytes.len], bytes[0..bytes.len]);
    self.length = bytes.len;
}

fn getAllBytes(self: *Bson) []const u8 {
    return self.buffer[4..self.length];
}

fn getBytes(self: *Bson, len: usize) []u8 {
    const bytesToGet: usize = self.pos + len;
    const res = self.buffer[self.pos..bytesToGet];
    self.pos += len;
    return res;
}

fn getByte(self: *Bson) []const u8 {
    const bytesToGet: usize = self.pos + 1;
    const res = self.buffer[self.pos..bytesToGet];
    self.pos += 1;
    return res;
}

fn putDocLen(self: *Bson) !void {
    const _len: u32 = @intCast(self.length);
    const len = _len - 4;
    const data: [4]u8 = @as([4]u8, @bitCast(len));

    @memcpy(self.buffer[0..4], data[0..4]);
}

fn getDocLen(self: *Bson) u32 {
    self.pos += 4;
    const len: u32 = @bitCast(@as(u32, self.buffer[0]) |
        (@as(u32, self.buffer[1]) << 8) |
        (@as(u32, self.buffer[2]) << 16) |
        (@as(u32, self.buffer[3]) << 24));
    return len;
}

fn putU64(self: *Bson, value: u64) !void {
    const data: [8]u8 = @as([8]u8, @bitCast(value));

    try self.putBytes(data[0..]);
}

fn getU64(self: *Bson) u64 {
    const endIndex = self.pos + 8;

    const data: []u8 = self.buffer[self.pos..endIndex];
    self.pos += 8;
    return @bitCast(@as(u64, data[0]) |
        (@as(u64, data[1]) << 8) |
        (@as(u64, data[2]) << 16) |
        (@as(u64, data[3]) << 24) |
        (@as(u64, data[4]) << 32) |
        (@as(u64, data[5]) << 40) |
        (@as(u64, data[6]) << 48) |
        (@as(u64, data[7]) << 56));
}

fn putI64(self: *Bson, value: i64) !void {
    const data: [8]u8 = @as([8]u8, @bitCast(value));

    try self.putBytes(data[0..]);
}

fn getI64(self: *Bson) i64 {
    const endIndex = self.pos + 8;

    const data: []u8 = self.buffer[self.pos..endIndex];
    self.pos += 8;

    return @bitCast(@as(i64, data[0]) |
        (@as(i64, data[1]) << 8) |
        (@as(i64, data[2]) << 16) |
        (@as(i64, data[3]) << 24) |
        (@as(i64, data[4]) << 32) |
        (@as(i64, data[5]) << 40) |
        (@as(i64, data[6]) << 48) |
        (@as(i64, data[7]) << 56));
}

fn putU32(self: *Bson, value: u32) !void {
    const data: [4]u8 = @as([4]u8, @bitCast(value));

    try self.putBytes(data[0..]);
}

fn getU32(self: *Bson) u32 {
    const endIndex = self.pos + 4;

    const data = self.buffer[self.pos..endIndex];
    self.pos += 4;
    return @bitCast(@as(u32, data[0]) |
        (@as(u32, data[1]) << 8) |
        (@as(u32, data[2]) << 16) |
        (@as(u32, data[3]) << 24));
}

fn putI32(self: *Bson, value: i32) !void {
    const data: [4]u8 = @as([4]u8, @bitCast(value));

    try self.putBytes(data[0..]);
}

fn getI32(self: *Bson) i32 {
    const endIndex = self.pos + 4;

    const data: []u8 = self.buffer[self.pos..endIndex];
    self.pos += 4;

    return @bitCast(@as(i32, data[0]) |
        (@as(i32, data[1]) << 8) |
        (@as(i32, data[2]) << 16) |
        (@as(i32, data[3]) << 24));
}

fn putF64(self: *Bson, value: f64) !void {
    const data: [8]u8 = @as([8]u8, @bitCast(value));

    try self.putBytes(data[0..]);
}

fn getF64(self: *Bson) f64 {
    const endIndex = self.pos + 8;

    const data: []u8 = self.buffer[self.pos..endIndex];
    self.pos += 8;

    return @bitCast(@as(u64, data[0]) |
        (@as(u64, data[1]) << 8) |
        (@as(u64, data[2]) << 16) |
        (@as(u64, data[3]) << 24) |
        (@as(u64, data[4]) << 32) |
        (@as(u64, data[5]) << 40) |
        (@as(u64, data[6]) << 48) |
        (@as(u64, data[7]) << 56));
}

fn putF128(self: *Bson, value: f128) !void {
    const data: [16]u8 = @as([16]u8, @bitCast(value));

    try self.putBytes(data[0..]);
}

fn getF128(self: *Bson) f128 {
    const endIndex = self.pos + 16;

    const data: []u8 = self.buffer[self.pos..endIndex];
    self.pos += 16;

    return @bitCast(@as(u128, data[0]) |
        (@as(u128, data[1]) << 8) |
        (@as(u128, data[2]) << 16) |
        (@as(u128, data[3]) << 24) |
        (@as(u128, data[4]) << 32) |
        (@as(u128, data[5]) << 40) |
        (@as(u128, data[6]) << 48) |
        (@as(u128, data[7]) << 56) |
        (@as(u128, data[8]) << 64) |
        (@as(u128, data[9]) << 72) |
        (@as(u128, data[10]) << 80) |
        (@as(u128, data[11]) << 88) |
        (@as(u128, data[12]) << 96) |
        (@as(u128, data[13]) << 104) |
        (@as(u128, data[14]) << 112) |
        (@as(u128, data[15]) << 120));
}

fn putFieldType(self: *Bson, value: u8) !void {
    const data: [1]u8 = @as([1]u8, @bitCast(value));

    try self.putBytes(data[0..]);
}

fn getFieldType(self: *Bson) u8 {
    const ft: []u8 = self.buffer[self.pos .. self.pos + 1];
    self.pos += 1;
    return ft[0];
}

fn putFieldLen(self: *Bson, value: usize) !void {
    const len: u32 = @intCast(value);
    self.putU32(len);
}

fn getFieldLen(self: *Bson) u32 {
    return self.getU32();
}

fn clear(self: *Bson) void {
    self.length = 0;
}

pub fn ser(self: *Bson, value: anytype) ![]const u8 {
    const info = @typeInfo(@TypeOf(value));
    inline for (info.Struct.fields) |field| {
        const fvalue = @field(value, field.name);
        const t = @typeInfo(@TypeOf(fvalue));

        switch (t) {
            .Int => |iinfo| {
                switch (iinfo.bits) {
                    8 => {},
                    32 => {
                        try self.putFieldType(16);
                        try self.putBytes(field.name[0..]);
                        try self.putBytes("\x00"[0..]);
                        try self.putI32(@field(value, field.name));
                    },
                    64 => {
                        switch (iinfo.signedness) {
                            .signed => {
                                try self.putFieldType(18);
                                try self.putBytes(field.name[0..]);
                                try self.putBytes("\x00"[0..]);
                                try self.putI64(@field(value, field.name));
                            },
                            .unsigned => {
                                try self.putFieldType(17);
                                try self.putBytes(field.name[0..]);
                                try self.putBytes("\x00"[0..]);
                                try self.putU64(@field(value, field.name));
                            },
                        }
                    },
                    else => {},
                }
            },
            .Float => |finfo| {
                switch (finfo.bits) {
                    64 => {
                        try self.putFieldType(1);
                        try self.putBytes(field.name[0..]);
                        try self.putBytes("\x00"[0..]);
                        try self.putF64(@field(value, field.name));
                    },
                    128 => {
                        try self.putFieldType(19);
                        try self.putBytes(field.name[0..]);
                        try self.putBytes("\x00"[0..]);
                        try self.putF128(@field(value, field.name));
                    },
                    else => {},
                }
            },
            .Pointer => {
                try self.putFieldType(2);
                try self.putBytes(field.name[0..]);
                try self.putBytes("\x00"[0..]);
                const len: u32 = @intCast(@field(value, field.name).len);
                try self.putU32(len);
                try self.putBytes(@field(value, field.name));
            },
            .Bool => {
                try self.putFieldType(8);
                try self.putBytes(field.name[0..]);
                try self.putBytes("\x00"[0..]);
                if (@field(value, field.name) == true) {
                    try self.putBytes("\x01"[0..]);
                } else {
                    try self.putBytes("\x00"[0..]);
                }
            },
            else => {},
        }
    }
    try self.putDocLen();
    return self.buffer[0..self.length];
}

pub fn de(self: *Bson, comptime T: type) !T {
    const docLen: u32 = self.getDocLen();
    const info = @typeInfo(T);

    var obj: T = T{};

    while (self.pos < docLen - 1) {
        const fieldType: BsonTypes = @enumFromInt(self.getFieldType());

        switch (fieldType) {
            .String => {
                const endIndex = std.mem.indexOf(u8, self.buffer[self.pos..], "\x00");
                if (endIndex) |ei| {
                    const fname: []u8 = self.getBytes(ei);
                    _ = self.getByte();
                    const fieldLen = self.getU32();
                    const fvalue: []u8 = self.getBytes(fieldLen);
                    inline for (info.Struct.fields) |field| {
                        // std.debug.print("type: {any}", .{field.type});
                        if (std.mem.eql(u8, field.name, fname) and field.type == []const u8) {
                            @field(obj, field.name) = @as(field.type, fvalue);
                            break;
                        }
                    }
                }
            },
            .Int32 => {
                const endIndex = std.mem.indexOf(u8, self.buffer[self.pos..], "\x00");
                if (endIndex) |ei| {
                    const fname = self.getBytes(ei);
                    _ = self.getByte();
                    const fvalue = self.getI32();
                    inline for (info.Struct.fields) |field| {
                        if (std.mem.eql(u8, field.name, fname) and field.type == i32) {
                            @field(obj, field.name) = fvalue;
                            break;
                        }
                    }
                }
            },
            .Int64 => {
                const endIndex = std.mem.indexOf(u8, self.buffer[self.pos..], "\x00");
                if (endIndex) |ei| {
                    const fname = self.getBytes(ei);
                    _ = self.getByte();
                    const fvalue = self.getI64();
                    inline for (info.Struct.fields) |field| {
                        if (std.mem.eql(u8, field.name, fname) and field.type == i64) {
                            @field(obj, field.name) = fvalue;
                            break;
                        }
                    }
                }
            },
            .Bool => {
                const endIndex = std.mem.indexOf(u8, self.buffer[self.pos..], "\x00");
                if (endIndex) |ei| {
                    const fname = self.getBytes(ei);
                    _ = self.getByte();
                    const fvalue = self.getByte();
                    inline for (info.Struct.fields) |field| {
                        if (std.mem.eql(u8, field.name, fname) and field.type == bool) {
                            if (fvalue[0] == 1) {
                                @field(obj, field.name) = true;
                            } else {
                                @field(obj, field.name) = false;
                            }
                            break;
                        }
                    }
                }
            },
            .Decimal => {
                const endIndex = std.mem.indexOf(u8, self.buffer[self.pos..], "\x00");
                if (endIndex) |ei| {
                    const fname = self.getBytes(ei);
                    _ = self.getByte();
                    const fvalue = self.getF128();
                    inline for (info.Struct.fields) |field| {
                        if (std.mem.eql(u8, field.name, fname) and field.type == f128) {
                            @field(obj, field.name) = fvalue;
                            break;
                        }
                    }
                }
            },
            .Double => {
                const endIndex = std.mem.indexOf(u8, self.buffer[self.pos..], "\x00");
                if (endIndex) |ei| {
                    const fname = self.getBytes(ei);
                    _ = self.getByte();
                    const fvalue = self.getF64();
                    inline for (info.Struct.fields) |field| {
                        if (std.mem.eql(u8, field.name, fname) and field.type == f64) {
                            @field(obj, field.name) = fvalue;
                            break;
                        }
                    }
                }
            },
            .UInt64 => {
                const endIndex = std.mem.indexOf(u8, self.buffer[self.pos..], "\x00");
                if (endIndex) |ei| {
                    const fname = self.getBytes(ei);
                    _ = self.getByte();
                    const fvalue = self.getU64();
                    inline for (info.Struct.fields) |field| {
                        if (std.mem.eql(u8, field.name, fname) and field.type == u64) {
                            @field(obj, field.name) = fvalue;
                            break;
                        }
                    }
                }
            },
        }
    }

    return obj;
}

const Person = struct {
    name: []const u8 = undefined,
    age: i32 = undefined,
    salary: i64 = undefined,
    tax: f64 = undefined,
    is_working: bool = false,
};

test "to-bson" {
    const p = Person{
        .age = 56,
        .name = "lala amarnath",
        .salary = 2147483647,
        .tax = 8.987987789789,
        .is_working = true,
    };
    var allocator = std.testing.allocator;
    var bson = try Bson.init(&allocator, 32);
    defer bson.deinit();

    const file = try std.fs.cwd().createFile(
        "test.bson",
        .{ .read = true },
    );
    defer file.close();

    const out = try bson.ser(p);
    std.debug.print("\nto bson: {any}\n", .{out});

    const bytes_written = try file.writeAll(out);
    _ = bytes_written;
}

test "from-bson" {
    var allocator = std.testing.allocator;

    var bson = try Bson.init(&allocator, 32);
    defer bson.deinit();

    const file = try std.fs.cwd().openFile(
        "test.bson",
        .{},
    );
    defer file.close();

    var buff: [2048]u8 = undefined;

    const len = try file.readAll(&buff);
    try bson.putFromFile(buff[0..len]);
    const _p = try bson.de(Person);
    std.debug.print("\nfrom bson:\nTax: {},\nName: {s},\nIsWorking: {?},\nSalary: {},\nAge: {d}\n", .{ _p.tax, _p.name, _p.is_working, _p.salary, _p.age });
}
