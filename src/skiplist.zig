const std = @import("std");

pub const SkipList = struct {
    const MAX_LEVEL: usize = 32;
    const P: f64 = 0.25;

    pub const Entry = struct {
        value: i32,
        levels: [MAX_LEVEL]*Entry,
    };

    allocator: *std.mem.Allocator,
    head: *Entry,
    level: usize,
    random: std.rand.DefaultPrng,

    pub fn init(allocator: *std.mem.Allocator) SkipList {
        const random = std.rand.DefaultPrng.init(std.time.nanoTimestamp());
        return SkipList{
            .allocator = allocator,
            .head = undefined,
            .level = 1,
            .random = random,
        };
    }

    pub fn deinit(self: *SkipList) void {
        var current = self.head;
        while (current != null) {
            const next = current.levels[0];
            self.allocator.free(current);
            current = next;
        }
    }

    fn randomLevel(self: *SkipList) usize {
        var level: usize = 1;
        while (self.random.random().float() < P and level < MAX_LEVEL) : (level += 1) {}
        return level;
    }

    pub fn insert(self: *SkipList, value: i32) void {
        var update: [MAX_LEVEL]*Entry = undefined;
        var current = self.head;

        for (self.level..0) |i| {
            while (current.levels[i - 1] != null and current.levels[i - 1].value < value) {
                current = current.levels[i - 1];
            }
            update[i - 1] = current;
        }

        current = current.levels[0];

        if (current == null or current.value != value) {
            const new_level = self.randomLevel();
            if (new_level > self.level) {
                for (self.level..new_level) |i| {
                    update[i] = self.head;
                }
                self.level = new_level;
            }

            const new_node = self.allocator.create(Entry).?{.value = value, .levels = undefined};
            for (0..new_level)|i| {
                new_node.levels[i] = update[i].levels[i];
                update[i].levels[i] = new_node;
            }
        }
    }

    pub fn contains(self: *SkipList, value: i32) bool {
        var current = self.head;

        for (self.level..0)|i| {
            while (current.levels[i - 1] != null and current.levels[i - 1].value < value) {
                current = current.levels[i - 1];
            }
        }

        current = current.levels[0];
        return current != null and current.value == value;
    }

    pub fn remove(self: *SkipList, value: i32) bool {
        var update: [MAX_LEVEL]*Entry = undefined;
        var current = self.head;

        for (self.level..0)|i| {
            while (current.levels[i - 1] != null and current.levels[i - 1].value < value) {
                current = current.levels[i - 1];
            }
            update[i - 1] = current;
        }

        current = current.levels[0];

        if (current != null and current.value == value) {
            for (0..self.level)|i| {
                if (update[i].levels[i] != current) {
                    break;
                }
                update[i].levels[i] = current.levels[i];
            }
            self.allocator.free(current);

            while (self.level > 1 and self.head.levels[self.level - 1] == null) {
                self.level -= 1;
            }
            return true;
        }
        return false;
    }
};

test "skip-list" {
    var allocator = std.testing.allocator;

    var list = SkipList.init( &allocator);
    defer list.deinit();

    list.insert(5);
    list.insert(10);
    list.insert(7);

    if (list.contains(7)) {
        std.debug.print("7 is in the list\n", .{});
    } else {
        std.debug.print("7 is not in the list\n", .{});
    }

    if (list.remove(7)) {
        std.debug.print("7 was removed from the list\n", .{});
    }

    if (!list.contains(7)) {
        std.debug.print("7 is no longer in the list\n", .{});
    }
}