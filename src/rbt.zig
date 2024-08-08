const std = @import("std");

const Color = enum { Red, Black };

const Node = struct {
    key: i32,
    value: i32,
    color: Color,
    left: ?*Node,
    right: ?*Node,
    parent: ?*Node,
};

const RedBlackTree = struct {
    root: ?*Node,

    pub fn init() RedBlackTree {
        return RedBlackTree{ .root = null };
    }

    fn leftRotate(self: *RedBlackTree, x: *Node) void {
        const y = x.right.?;
        x.right = y.left;
        if (y.left) |left| {
            left.parent = x;
        }
        y.parent = x.parent;
        if (x.parent) |parent| {
            if (x == parent.left) {
                parent.left = y;
            } else {
                parent.right = y;
            }
        } else {
            self.root = y;
        }
        y.left = x;
        x.parent = y;
    }

    fn rightRotate(self: *RedBlackTree, x: *Node) void {
        const y = x.left.?;
        x.left = y.right;
        if (y.right) |right| {
            right.parent = x;
        }
        y.parent = x.parent;
        if (x.parent) |parent| {
            if (x == parent.right) {
                parent.right = y;
            } else {
                parent.left = y;
            }
        } else {
            self.root = y;
        }
        y.right = x;
        x.parent = y;
    }

    fn insertFixup(self: *RedBlackTree, mut z: *Node) void {
        while (z.parent and z.parent.?.color == .Red) {
            if (z.parent == z.parent.?.parent.?.left) {
                var y = z.parent.?.parent.?.right;
                if (y and y.?.color == .Red) {
                    z.parent.?.color = .Black;
                    y.?.color = .Black;
                    z.parent.?.parent.?.color = .Red;
                    z = z.parent.?.parent.?;
                } else {
                    if (z == z.parent.?.right) {
                        z = z.parent.?;
                        self.leftRotate(z);
                    }
                    z.parent.?.color = .Black;
                    z.parent.?.parent.?.color = .Red;
                    self.rightRotate(z.parent.?.parent.?);
                }
            } else {
                var y = z.parent.?.parent.?.left;
                if (y and y.?.color == .Red) {
                    z.parent.?.color = .Black;
                    y.?.color = .Black;
                    z.parent.?.parent.?.color = .Red;
                    z = z.parent.?.parent.?;
                } else {
                    if (z == z.parent.?.left) {
                        z = z.parent.?;
                        self.rightRotate(z);
                    }
                    z.parent.?.color = .Black;
                    z.parent.?.parent.?.color = .Red;
                    self.leftRotate(z.parent.?.parent.?);
                }
            }
        }
        self.root.?.color = .Black;
    }

    pub fn insert(self: *RedBlackTree, key: i32, value: i32) void {
        var z = std.heap.page_allocator.create(Node).?;
        z.* = Node{
            .key = key,
            .value = value,
            .color = .Red,
            .left = null,
            .right = null,
            .parent = null,
        };

        var y: ?*Node = null;
        var x = self.root;

        while (x) |x_ptr| {
            y = x_ptr;
            if (z.key < x_ptr.key) {
                x = x_ptr.left;
            } else {
                x = x_ptr.right;
            }
        }

        z.parent = y;
        if (!y) {
            self.root = z;
        } else if (z.key < y.?.key) {
            y.?.left = z;
        } else {
            y.?.right = z;
        }

        if (!z.parent) {
            z.color = .Black;
            return;
        }

        if (!z.parent.?.parent) {
            return;
        }

        self.insertFixup(z);
    }

    fn searchNode(self: *const RedBlackTree, key: i32) ?*const Node {
        var current = self.root;
        while (current) |c| {
            if (key < c.key) {
                current = c.left;
            } else if (key > c.key) {
                current = c.right;
            } else {
                return c;
            }
        }
        return null;
    }

    pub fn search(self: *const RedBlackTree, key: i32) ?i32 {
        return switch (self.searchNode(key)) {
            null => null,
            |node| node.value,
        };
    }

    fn deinitNode(allocator: *std.mem.Allocator, node: ?*Node) void {
        if (node) |n| {
            self.deinitNode(allocator, n.left);
            self.deinitNode(allocator, n.right);
            allocator.destroy(n);
        }
    }

    pub fn deinit(self: *RedBlackTree, allocator: *std.mem.Allocator) void {
        self.deinitNode(allocator, self.root);
        self.root = null;
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var tree = RedBlackTree.init();

    tree.insert(10, 100);
    tree.insert(20, 200);
    tree.insert(30, 300);

    const value = tree.search(20);
    if (value) |v| {
        std.debug.print("Found key 20 with value {}\n", .{v});
    } else {
        std.debug.print("Key 20 not found\n", .{});
    }

    tree.deinit(allocator);
}
