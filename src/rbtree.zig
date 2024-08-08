const std = @import("std");
const mem = std.mem;

const Color = enum { Red, Black };

const Node = struct {
    key: i32,
    value: i32,
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
    z.value = 9000000;
    z.left = null;
    z.right = null;
    return RedBlackTree{ .root = z, .TNULL = z, .allocator = allocator };
}

pub fn insert(self: *RedBlackTree, key: i32) !void {
    const z = try self.allocator.create(Node);
    z.key = key;
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

// pub fn delete(self: *RedBlackTree, key: i32) void {
//     self.deleteNode(self.root.?, key);
// }

// fn deleteNode(self: *RedBlackTree, node: *Node, key: i32) void {
//     var z: *Node = self.TNULL.?;
//     var x: *Node = undefined;
//     var y: *Node = undefined;

//     while (node != self.TNULL) {
//         if (node.key == key) {
//             z = node;
//         }

//         if (node.key <= key) {
//             node = node.right;
//         } else {
//             node = node.left;
//         }
//     }

//     if (z == self.TNULL) {
//         std.debug.print("Key not found in the tree", .{});
//         return;
//     }

//     y = z;
//     var y_original_color: Color = y.color;
//     if (z.left == self.TNULL) {
//         x = z.right;
//         rbTransplant(z, z.right);
//     } else if (z.right == self.TNULL) {
//         x = z.left;
//         rbTransplant(z, z.left);
//     } else {
//         y = minimum(z.right);
//         y_original_color = y.color;
//         x = y.right;
//         if (y.parent == z) {
//             x.parent = y;
//         } else {
//             rbTransplant(y, y.right);
//             y.right = z.right;
//             y.right.?.parent = y;
//         }

//         rbTransplant(z, y);
//         y.left = z.left;
//         y.left.?.parent = y;
//         y.color = z.color;
//     }
//     self.allocator.destroy(z);
//     if (y_original_color == 0) {
//         deleteFix(x);
//     }
// }

// fn deleteFix(self: *RedBlackTree, x: *Node) void {
//     var s: *Node = undefined;
//     while (x != self.root and x.color == .Black) {
//         if (x == x.parent.?.left) {
//             s = x.parent.?.right;
//             if (s.color == .Red) {
//                 s.color = .Black;
//                 x.parent.?.color = .Red;
//                 leftRotate(x.parent);
//                 s = x.parent.?.right;
//             }

//             if (s.left.?.color == .Black and s.right.?.color == .Black) {
//                 s.color = .Red;
//                 x = x.parent;
//             } else {
//                 if (s.right.?.color == .Black) {
//                     s.left.?.color = .Black;
//                     s.color = .Red;
//                     rightRotate(s);
//                     s = x.parent.?.right;
//                 }

//                 s.color = x.parent.?.color;
//                 x.parent.?.color = .Black;
//                 s.right.?.color = .Black;
//                 leftRotate(x.parent);
//                 x = self.root;
//             }
//         } else {
//             s = x.parent.?.left;
//             if (s.color == .Red) {
//                 s.color = .Black;
//                 x.parent.?.color = .Red;
//                 rightRotate(x.parent);
//                 s = x.parent.?.left;
//             }

//             if (s.right.?.color == .Black and s.right.?.color == .Black) {
//                 s.color = .Red;
//                 x = x.parent;
//             } else {
//                 if (s.left.?.color == .Black) {
//                     s.right.?.color = .Black;
//                     s.color = .Red;
//                     leftRotate(s);
//                     s = x.parent.?.left;
//                 }

//                 s.color = x.parent.?.color;
//                 x.parent.?.color = .Black;
//                 s.left.color = .Black;
//                 rightRotate(x.parent);
//                 x = self.root;
//             }
//         }
//     }
//     x.color = .Black;
// }

// fn rbTransplant(self: *RedBlackTree, u: *Node, v: *Node) void {
//     if (u.parent == null) {
//         self.root = v;
//     } else if (u == u.parent.?.left) {
//         u.parent.?.left = v;
//     } else {
//         u.parent.?.right = v;
//     }
//     v.parent = u.parent;
// }

// fn minimum(self: *RedBlackTree, node: *Node) *Node {
//     while (node.left != self.TNULL) {
//         node = node.left;
//     }
//     return node;
// }

// fn maximum(self: *RedBlackTree, node: *Node) *Node {
//     while (node.right != self.TNULL) {
//         node = node.right;
//     }
//     return node;
// }

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

    try tree.insert(30);
    try tree.insert(200);
    try tree.insert(300);

    if (tree.search(200)) |value| {
        std.debug.print("\nFound: {}\n", .{value.key});
        value.key = 800;
    } else {
        std.debug.print("\nNot found\n", .{});
    }
     
    if (tree.search(200)) |value| {
        std.debug.print("\nFound: {}\n", .{value.key});
    } else {
        std.debug.print("\nNot found\n", .{});
    }
}
