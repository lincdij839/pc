// PC Language Interpreter - Tree-walking interpreter
const std = @import("std");
const ast = @import("ast.zig");
const Node = ast.Node;

pub const Value = union(enum) {
    Int: i64,
    Float: f64,
    String: []const u8,
    Bool: bool,
    None,
    List: std.ArrayList(Value),
    Dict: std.StringHashMap(Value),
    Function: struct {
        params: std.ArrayList(*Node),
        body: *Node,
    },
    Return: *Value,

    pub fn format(
        self: Value,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .Int => |v| try writer.print("{}", .{v}),
            .Float => |v| try writer.print("{d}", .{v}),
            .String => |v| try writer.print("{s}", .{v}),
            .Bool => |v| try writer.print("{}", .{v}),
            .None => try writer.print("None", .{}),
            .List => try writer.print("<list>", .{}),
            .Dict => try writer.print("<dict>", .{}),
            .Function => try writer.print("<function>", .{}),
            .Return => |v| try writer.print("{}", .{v.*}),
        }
    }
};

pub const InterpreterError = error{
    UndefinedVariable,
    TypeError,
    RuntimeError,
    DivisionByZero,
    OutOfMemory,
} || std.fs.File.WriteError;

pub const Interpreter = struct {
    allocator: std.mem.Allocator,
    globals: std.StringHashMap(Value),
    locals: ?*std.StringHashMap(Value),
    stdout: std.fs.File.Writer,
    return_value: ?Value,

    pub fn init(allocator: std.mem.Allocator) Interpreter {
        return .{
            .allocator = allocator,
            .globals = std.StringHashMap(Value).init(allocator),
            .locals = null,
            .stdout = std.io.getStdOut().writer(),
            .return_value = null,
        };
    }

    pub fn deinit(self: *Interpreter) void {
        self.globals.deinit();
    }

    pub fn execute(self: *Interpreter, program: *Node) !void {
        if (program.* != .Program) {
            return InterpreterError.RuntimeError;
        }

        for (program.Program.statements.items) |stmt| {
            _ = try self.eval(stmt);
        }
    }

    pub fn eval(self: *Interpreter, node: *Node) InterpreterError!Value {
        return switch (node.*) {
            .LiteralInt => |v| Value{ .Int = v.value },
            .LiteralFloat => |v| Value{ .Float = v.value },
            .LiteralString => |v| Value{ .String = v.value },
            .LiteralBool => |v| Value{ .Bool = v.value },

            .Identifier => |v| blk: {
                // Check locals first, then globals
                if (self.locals) |locals| {
                    if (locals.get(v.name)) |value| {
                        break :blk value;
                    }
                }
                const value = self.globals.get(v.name) orelse {
                    std.debug.print("Undefined variable: {s}\n", .{v.name});
                    return InterpreterError.UndefinedVariable;
                };
                break :blk value;
            },

            .BinaryOp => |v| try self.evalBinaryOp(v.operator, v.left, v.right),

            .Assignment => |v| blk: {
                const value = try self.eval(v.value);
                if (v.target.* == .Identifier) {
                    // Assign to locals if in function scope, otherwise globals
                    if (self.locals) |locals| {
                        try locals.put(v.target.Identifier.name, value);
                    } else {
                        try self.globals.put(v.target.Identifier.name, value);
                    }
                }
                break :blk value;
            },

            .VariableDecl => |v| blk: {
                const value = if (v.initializer) |initializer| 
                    try self.eval(initializer)
                else 
                    Value.None;
                try self.globals.put(v.name, value);
                break :blk value;
            },

            .FunctionCall => |v| try self.evalFunctionCall(v.callee, v.arguments),

            .FunctionDef => |v| blk: {
                const func_value = Value{
                    .Function = .{
                        .params = v.params,
                        .body = v.body,
                    },
                };
                try self.globals.put(v.name, func_value);
                break :blk Value.None;
            },

            .ReturnStatement => |v| blk: {
                const ret_val = if (v.value) |val| 
                    try self.eval(val)
                else 
                    Value.None;
                
                // Store return value and create Return wrapper
                self.return_value = ret_val;
                const ret_ptr = try self.allocator.create(Value);
                ret_ptr.* = ret_val;
                break :blk Value{ .Return = ret_ptr };
            },

            .IfStatement => |v| blk: {
                const condition = try self.eval(v.condition);
                const is_true = switch (condition) {
                    .Bool => |b| b,
                    .Int => |i| i != 0,
                    .None => false,
                    else => true,
                };

                if (is_true) {
                    _ = try self.eval(v.then_branch);
                } else if (v.else_branch) |else_branch| {
                    _ = try self.eval(else_branch);
                }
                break :blk Value.None;
            },

            .WhileLoop => |v| blk: {
                while (true) {
                    const condition = try self.eval(v.condition);
                    const is_true = switch (condition) {
                        .Bool => |b| b,
                        .Int => |i| i != 0,
                        else => false,
                    };
                    if (!is_true) break;
                    _ = try self.eval(v.body);
                }
                break :blk Value.None;
            },

            .ForLoop => |v| blk: {
                // Evaluate the iterable
                const iterable = try self.eval(v.iterable);
                
                // For now, support range-like iteration on integers
                if (iterable == .Int) {
                    const max = iterable.Int;
                    var i: i64 = 0;
                    while (i < max) : (i += 1) {
                        // Set iterator variable
                        if (v.iterator.* == .Identifier) {
                            try self.globals.put(v.iterator.Identifier.name, Value{ .Int = i });
                        }
                        _ = try self.eval(v.body);
                    }
                }
                break :blk Value.None;
            },

            .Block => |v| blk: {
                var result: Value = .None;
                for (v.statements.items) |stmt| {
                    result = try self.eval(stmt);
                    // If we hit a return statement, propagate it up
                    if (result == .Return) {
                        break :blk result;
                    }
                }
                break :blk result;
            },

            else => {
                std.debug.print("Unimplemented node type: {s}\n", .{@tagName(node.*)});
                return Value.None;
            },
        };
    }

    fn evalBinaryOp(self: *Interpreter, operator: []const u8, left: *Node, right: *Node) !Value {
        const left_val = try self.eval(left);
        const right_val = try self.eval(right);

        // Debug output
        // std.debug.print("BinaryOp: {s} {s} {s}\n", .{@tagName(left_val), operator, @tagName(right_val)});

        // Integer operations
        if (left_val == .Int and right_val == .Int) {
            const l = left_val.Int;
            const r = right_val.Int;

            if (std.mem.eql(u8, operator, "+")) return Value{ .Int = l + r };
            if (std.mem.eql(u8, operator, "-")) return Value{ .Int = l - r };
            if (std.mem.eql(u8, operator, "*")) return Value{ .Int = l * r };
            if (std.mem.eql(u8, operator, "/")) {
                if (r == 0) return InterpreterError.DivisionByZero;
                return Value{ .Int = @divTrunc(l, r) };
            }
            if (std.mem.eql(u8, operator, "%")) return Value{ .Int = @mod(l, r) };
            if (std.mem.eql(u8, operator, "==")) return Value{ .Bool = l == r };
            if (std.mem.eql(u8, operator, "!=")) return Value{ .Bool = l != r };
            if (std.mem.eql(u8, operator, "<")) return Value{ .Bool = l < r };
            if (std.mem.eql(u8, operator, ">")) return Value{ .Bool = l > r };
            if (std.mem.eql(u8, operator, "<=")) return Value{ .Bool = l <= r };
            if (std.mem.eql(u8, operator, ">=")) return Value{ .Bool = l >= r };
        }

        // String concatenation
        if (left_val == .String and right_val == .String and std.mem.eql(u8, operator, "+")) {
            const concat_result = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ left_val.String, right_val.String });
            return Value{ .String = concat_result };
        }

        std.debug.print("Type error in binary operation: {s} {s} {s}\n", .{@tagName(left_val), operator, @tagName(right_val)});
        return InterpreterError.TypeError;
    }

    fn evalFunctionCall(self: *Interpreter, callee: *Node, arguments: std.ArrayList(*Node)) !Value {
        // Built-in functions
        if (callee.* == .Identifier) {
            const name = callee.Identifier.name;

            // print()
            if (std.mem.eql(u8, name, "print")) {
                for (arguments.items) |arg| {
                    const val = try self.eval(arg);
                    try self.stdout.print("{}", .{val});
                }
                try self.stdout.print("\n", .{});
                return Value.None;
            }

            // len()
            if (std.mem.eql(u8, name, "len")) {
                if (arguments.items.len > 0) {
                    const val = try self.eval(arguments.items[0]);
                    if (val == .String) {
                        return Value{ .Int = @intCast(val.String.len) };
                    }
                }
                return Value{ .Int = 0 };
            }

            // range()
            if (std.mem.eql(u8, name, "range")) {
                if (arguments.items.len > 0) {
                    const val = try self.eval(arguments.items[0]);
                    if (val == .Int) {
                        return val; // Return the max value for iteration
                    }
                }
                return Value{ .Int = 0 };
            }

            // str() - convert to string
            if (std.mem.eql(u8, name, "str")) {
                if (arguments.items.len > 0) {
                    const val = try self.eval(arguments.items[0]);
                    const str_val = switch (val) {
                        .Int => |i| try std.fmt.allocPrint(self.allocator, "{}", .{i}),
                        .Float => |f| try std.fmt.allocPrint(self.allocator, "{d}", .{f}),
                        .Bool => |b| if (b) "true" else "false",
                        .String => |s| s,
                        .None => "None",
                        else => "<object>",
                    };
                    return Value{ .String = str_val };
                }
                return Value{ .String = "" };
            }

            // int() - convert to integer
            if (std.mem.eql(u8, name, "int")) {
                if (arguments.items.len > 0) {
                    const val = try self.eval(arguments.items[0]);
                    const int_val = switch (val) {
                        .Int => |i| i,
                        .Float => |f| @as(i64, @intFromFloat(f)),
                        .Bool => |b| if (b) @as(i64, 1) else @as(i64, 0),
                        .String => |s| std.fmt.parseInt(i64, s, 10) catch 0,
                        else => 0,
                    };
                    return Value{ .Int = int_val };
                }
                return Value{ .Int = 0 };
            }

            // p64() - pack 64-bit integer to bytes
            if (std.mem.eql(u8, name, "p64")) {
                if (arguments.items.len > 0) {
                    const val = try self.eval(arguments.items[0]);
                    if (val == .Int) {
                        var result: [8]u8 = undefined;
                        std.mem.writeInt(u64, &result, @intCast(val.Int), .little);
                        const str = try self.allocator.dupe(u8, &result);
                        return Value{ .String = str };
                    }
                }
                return Value{ .String = "" };
            }

            // p32() - pack 32-bit integer to bytes
            if (std.mem.eql(u8, name, "p32")) {
                if (arguments.items.len > 0) {
                    const val = try self.eval(arguments.items[0]);
                    if (val == .Int) {
                        var result: [4]u8 = undefined;
                        std.mem.writeInt(u32, &result, @intCast(val.Int), .little);
                        const str = try self.allocator.dupe(u8, &result);
                        return Value{ .String = str };
                    }
                }
                return Value{ .String = "" };
            }

            // hex() - convert to hex string
            if (std.mem.eql(u8, name, "hex")) {
                if (arguments.items.len > 0) {
                    const val = try self.eval(arguments.items[0]);
                    if (val == .Int) {
                        const hex_str = try std.fmt.allocPrint(self.allocator, "0x{x}", .{val.Int});
                        return Value{ .String = hex_str };
                    }
                }
                return Value{ .String = "" };
            }

            // unpack32() - unpack 32-bit integer from bytes
            if (std.mem.eql(u8, name, "unpack32")) {
                if (arguments.items.len > 0) {
                    const val = try self.eval(arguments.items[0]);
                    if (val == .String and val.String.len >= 4) {
                        const bytes = val.String[0..4];
                        const result = std.mem.readInt(u32, bytes[0..4], .little);
                        return Value{ .Int = @intCast(result) };
                    }
                }
                return Value{ .Int = 0 };
            }

            // unpack64() - unpack 64-bit integer from bytes
            if (std.mem.eql(u8, name, "unpack64")) {
                if (arguments.items.len > 0) {
                    const val = try self.eval(arguments.items[0]);
                    if (val == .String and val.String.len >= 8) {
                        const bytes = val.String[0..8];
                        const result = std.mem.readInt(u64, bytes[0..8], .little);
                        return Value{ .Int = @bitCast(result) };
                    }
                }
                return Value{ .Int = 0 };
            }

            // abs() - absolute value
            if (std.mem.eql(u8, name, "abs")) {
                if (arguments.items.len > 0) {
                    const val = try self.eval(arguments.items[0]);
                    if (val == .Int) {
                        const abs_val = if (val.Int < 0) -val.Int else val.Int;
                        return Value{ .Int = abs_val };
                    } else if (val == .Float) {
                        return Value{ .Float = @abs(val.Float) };
                    }
                }
                return Value{ .Int = 0 };
            }

            // max() - maximum of two values
            if (std.mem.eql(u8, name, "max")) {
                if (arguments.items.len >= 2) {
                    const val1 = try self.eval(arguments.items[0]);
                    const val2 = try self.eval(arguments.items[1]);
                    if (val1 == .Int and val2 == .Int) {
                        return Value{ .Int = @max(val1.Int, val2.Int) };
                    }
                }
                return Value{ .Int = 0 };
            }

            // min() - minimum of two values
            if (std.mem.eql(u8, name, "min")) {
                if (arguments.items.len >= 2) {
                    const val1 = try self.eval(arguments.items[0]);
                    const val2 = try self.eval(arguments.items[1]);
                    if (val1 == .Int and val2 == .Int) {
                        return Value{ .Int = @min(val1.Int, val2.Int) };
                    }
                }
                return Value{ .Int = 0 };
            }

            // pow() - power function
            if (std.mem.eql(u8, name, "pow")) {
                if (arguments.items.len >= 2) {
                    const base = try self.eval(arguments.items[0]);
                    const exp = try self.eval(arguments.items[1]);
                    if (base == .Int and exp == .Int) {
                        const result = std.math.pow(f64, @floatFromInt(base.Int), @floatFromInt(exp.Int));
                        return Value{ .Float = result };
                    }
                }
                return Value{ .Int = 0 };
            }

            // upper() - convert string to uppercase
            if (std.mem.eql(u8, name, "upper")) {
                if (arguments.items.len > 0) {
                    const val = try self.eval(arguments.items[0]);
                    if (val == .String) {
                        const result = try self.allocator.alloc(u8, val.String.len);
                        for (val.String, 0..) |c, i| {
                            result[i] = std.ascii.toUpper(c);
                        }
                        return Value{ .String = result };
                    }
                }
                return Value{ .String = "" };
            }

            // lower() - convert string to lowercase
            if (std.mem.eql(u8, name, "lower")) {
                if (arguments.items.len > 0) {
                    const val = try self.eval(arguments.items[0]);
                    if (val == .String) {
                        const result = try self.allocator.alloc(u8, val.String.len);
                        for (val.String, 0..) |c, i| {
                            result[i] = std.ascii.toLower(c);
                        }
                        return Value{ .String = result };
                    }
                }
                return Value{ .String = "" };
            }

            // User-defined functions
            if (self.globals.get(name)) |func_val| {
                if (func_val == .Function) {
                    // Create local scope for function execution
                    var local_scope = std.StringHashMap(Value).init(self.allocator);
                    defer local_scope.deinit();
                    
                    // Bind parameters to arguments
                    for (func_val.Function.params.items, 0..) |param, i| {
                        if (param.* == .Identifier) {
                            const arg_val = if (i < arguments.items.len)
                                try self.eval(arguments.items[i])
                            else
                                Value.None;
                            try local_scope.put(param.Identifier.name, arg_val);
                        }
                    }
                    
                    // Save previous locals and set new locals
                    const prev_locals = self.locals;
                    self.locals = &local_scope;
                    
                    // Execute function body
                    const result = try self.eval(func_val.Function.body);
                    
                    // Restore previous locals
                    self.locals = prev_locals;
                    
                    // If result is a Return wrapper, unwrap it
                    if (result == .Return) {
                        return result.Return.*;
                    }
                    
                    return result;
                }
            }
        }

        return Value.None;
    }

    pub fn registerBuiltin(self: *Interpreter, name: []const u8) !void {
        // Built-ins are handled directly in evalFunctionCall
        _ = self;
        _ = name;
    }
};
