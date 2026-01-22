// PC Language Standard Library - Built-in Functions
const std = @import("std");
const Value = @import("../interpreter.zig").Value;

pub const Builtins = struct {
    allocator: std.mem.Allocator,
    stdout: std.fs.File.Writer,

    pub fn init(allocator: std.mem.Allocator) Builtins {
        return .{
            .allocator = allocator,
            .stdout = std.io.getStdOut().writer(),
        };
    }

    // print(*args)
    pub fn print(self: *Builtins, args: []const Value) !Value {
        for (args, 0..) |arg, i| {
            if (i > 0) try self.stdout.print(" ", .{});
            try self.stdout.print("{}", .{arg});
        }
        try self.stdout.print("\n", .{});
        return Value.None;
    }

    // len(obj)
    pub fn len(self: *Builtins, args: []const Value) !Value {
        _ = self;
        if (args.len < 1) return Value{ .Int = 0 };

        return switch (args[0]) {
            .String => |s| Value{ .Int = @intCast(s.len) },
            else => Value{ .Int = 0 },
        };
    }

    // int(x)
    pub fn int(self: *Builtins, args: []const Value) !Value {
        _ = self;
        if (args.len < 1) return Value{ .Int = 0 };

        return switch (args[0]) {
            .Int => args[0],
            .Float => |f| Value{ .Int = @intFromFloat(f) },
            .Bool => |b| Value{ .Int = if (b) 1 else 0 },
            .String => |s| blk: {
                const parsed = std.fmt.parseInt(i64, s, 10) catch 0;
                break :blk Value{ .Int = parsed };
            },
            else => Value{ .Int = 0 },
        };
    }

    // str(x)
    pub fn str(self: *Builtins, args: []const Value) !Value {
        if (args.len < 1) return Value{ .String = "" };

        const result = switch (args[0]) {
            .String => args[0].String,
            .Int => |i| try std.fmt.allocPrint(self.allocator, "{}", .{i}),
            .Float => |f| try std.fmt.allocPrint(self.allocator, "{d}", .{f}),
            .Bool => |b| if (b) "true" else "false",
            .None => "None",
            else => "<object>",
        };

        return Value{ .String = result };
    }

    // range(n) or range(start, end)
    pub fn range(self: *Builtins, args: []const Value) !Value {
        _ = self;
        _ = args;
        // TODO: Return iterator object
        return Value.None;
    }
};
