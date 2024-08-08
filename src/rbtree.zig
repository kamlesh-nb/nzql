const std = @import("std");
const mem = std.mem;

const Color = enum { Red, Black };

const Node = struct {
    key: i32,
    value: []const u8,
    color: Color,
    left: ?*Node,
    right: ?*Node,
    parent: ?*Node,
};

const RedBlackTree = @This();

root: ?*Node,
TNULL: ?*Node,
allocator: mem.Allocator,

pub fn init(allocator: mem.Allocator) !RedBlackTree {
    const z = try allocator.create(Node);
    z.key = 0;
    z.value = "";
    z.left = null;
    z.right = null;
    return RedBlackTree{ .root = z, .TNULL = z, .allocator = allocator };
}

pub fn insert(self: *RedBlackTree, key: i32, value: []const u8) !void {
    const z = try self.allocator.create(Node);
    z.key = key;
    z.value = value;
    z.color = Color.Red;
    z.left = null;
    z.right = null;
    z.parent = null;

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

    if (y == null) {
        self.root = z;
    } else if (z.key < y.?.key) {
        y.?.left = z;
    } else {
        y.?.right = z;
    }

    if (z.parent == null) {
        z.color = Color.Black;
        return;
    }

    if (z.parent.?.parent == null) {
        return;
    }
}

fn fixInsert(self: *RedBlackTree, node: *Node) void {
    var u: *Node = undefined;
    while (node.parent.?.color == .Red) {
        if (node.parent == node.parent.?.parent.?.right) {
            u = node.parent.?.parent.?.left;
            if (u.color == .Red) {
                u.color = 0;
                node.parent.color = 0;
                node.parent.?.parent.?.color = 1;
                node = node.parent.?.parent;
            } else {
                if (node == node.parent.?.left) {
                    node = node.parent;
                    rightRotate(node);
                }
                node.parent.?.color = 0;
                node.parent.?.parent.?.color = .Red;
                leftRotate(node.parent.?.parent);
            }
        } else {
            u = node.parent.?.parent.?.right;

            if (u.color == .Red) {
                u.color = .Black;
                node.parent.?.color = .Black;
                node.parent.?.parent.?.color = .Red;
                node = node.parent.?.parent;
            } else {
                if (node == node.parent.?.right) {
                    node = node.parent;
                    leftRotate(node);
                }
                node.parent.?.color = .Black;
                node.parent.?.parent.?.color = .Red;
                rightRotate(node.parent.?.parent);
            }
        }
        if (node == self.root) {
            break;
        }
    }
    self.root.?.color = .Black;
}

fn searchNode(self: *RedBlackTree, key: i32) ?*Node {
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

fn search(self: *RedBlackTree, key: i32) ?*Node {
    return self.searchNode(key);
}

fn leftRotate(self: *RedBlackTree, x: *Node) void {
    var y: *Node = x.right;
    x.right = y.left;
    if (y.left != self.TNULL) {
        y.left.?.parent = x;
    }
    y.parent = x.parent;
    if (x.parent == null) {
        self.root = y;
    } else if (x == x.parent.?.left) {
        x.parent.?.left = y;
    } else {
        x.parent.?.right = y;
    }
    y.left = x;
    x.parent = y;
}

fn rightRotate(self: *RedBlackTree, x: *Node) void {
    var y: *Node = undefined;
    y = x.left;
    x.left = y.right;

    if (y.right != self.TNULL) {
        y.right.?.parent = x;
    }
    y.parent = x.parent;
    if (x.parent == null) {
        self.root = y;
    } else if (x == x.parent.?.right) {
        x.parent.?.right = y;
    } else {
        x.parent.?.left = y;
    }
    y.right = x;
    x.parent = y;
}

pub fn traverseTree(self: *RedBlackTree, node: ?*Node) void {
    if (node == null)
        return;
    self.traverseTree(node.?.left);
    if (node.?.key != 0) {
        std.debug.print("\nKey: {}, Value: {s}", .{ node.?.key, node.?.value });
    }
    self.traverseTree(node.?.right);
}

fn deinitNode(self: *RedBlackTree, node: ?*Node) void {
    if (node) |n| {
        if (n.left != null) {
            self.deinitNode(n.left);
        }
        if (n.right != null) {
            self.deinitNode(n.right);
        }
        self.allocator.destroy(n);
    }
}

pub fn deinit(self: *RedBlackTree) void {
    self.deinitNode(self.root);
}

test "rb" {
    var tree = try RedBlackTree.init(std.testing.allocator);
    defer tree.deinit();

    try tree.insert(40, "kamlesh");
    try tree.insert(10, "kamlesh");
    try tree.insert(50, "mehul");
    try tree.insert(20, "mehul");
    try tree.insert(60, "shilpa");
    try tree.insert(30, "shilpa");

    if (tree.search(60)) |value| {
        std.debug.print("\nFound: {}\n", .{value.key});
    } else {
        std.debug.print("\nNot found\n", .{});
    }

    tree.traverseTree(tree.root);
}
