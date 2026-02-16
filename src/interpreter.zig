// PC Language Interpreter - Tree-walking interpreter (Refactored)
const std = @import("std");
const ast = @import("ast.zig");
const Node = ast.Node;
const builtins = @import("stdlib/builtins.zig");

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
    arena: std.heap.ArenaAllocator,
    globals: std.StringHashMap(Value),
    scopes: std.ArrayList(std.StringHashMap(Value)),
    stdout: std.fs.File.Writer,
    return_flag: bool,
    return_value: Value,

    pub fn init(allocator: std.mem.Allocator) Interpreter {
        const arena = std.heap.ArenaAllocator.init(allocator);
        return .{
            .allocator = allocator,
            .arena = arena,
            .globals = std.StringHashMap(Value).init(allocator),
            .scopes = std.ArrayList(std.StringHashMap(Value)).init(allocator),
            .stdout = std.io.getStdOut().writer(),
            .return_flag = false,
            .return_value = Value.None,
        };
    }

    pub fn deinit(self: *Interpreter) void {
        self.globals.deinit();
        for (self.scopes.items) |*scope| {
            scope.deinit();
        }
        self.scopes.deinit();
        self.arena.deinit(); // Free all arena allocations at once
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

            .LiteralList => |v| blk: {
                var list = std.ArrayList(Value).init(self.allocator);
                for (v.elements.items) |elem| {
                    try list.append(try self.eval(elem));
                }
                break :blk Value{ .List = list };
            },

            .LiteralDict => |v| blk: {
                var dict = std.StringHashMap(Value).init(self.allocator);
                for (v.keys.items, v.values.items) |key_node, val_node| {
                    const key_val = try self.eval(key_node);
                    const val = try self.eval(val_node);
                    
                    // Convert key to string
                    const key_str = switch (key_val) {
                        .String => |s| s,
                        .Int => |i| try std.fmt.allocPrint(self.arena.allocator(), "{}", .{i}),
                        else => "unknown",
                    };
                    
                    try dict.put(key_str, val);
                }
                break :blk Value{ .Dict = dict };
            },

            .IndexAccess => |v| blk: {
                const obj = try self.eval(v.object);
                const idx = try self.eval(v.index);
                
                if (obj == .List and idx == .Int) {
                    const index = @as(usize, @intCast(idx.Int));
                    if (index < obj.List.items.len) {
                        break :blk obj.List.items[index];
                    }
                } else if (obj == .Dict) {
                    // Dict access by string key
                    const key_str = switch (idx) {
                        .String => |s| s,
                        .Int => |i| try std.fmt.allocPrint(self.arena.allocator(), "{}", .{i}),
                        else => "unknown",
                    };
                    
                    if (obj.Dict.get(key_str)) |value| {
                        break :blk value;
                    }
                }
                break :blk Value.None;
            },

            .SliceAccess => |v| blk: {
                const obj = try self.eval(v.object);
                
                // Get start and end indices
                const start_val = if (v.start) |s| try self.eval(s) else Value{ .Int = 0 };
                const end_val = if (v.end) |e| try self.eval(e) else null;
                
                if (start_val != .Int) {
                    break :blk Value.None;
                }
                
                const start_idx = @as(usize, @intCast(@max(0, start_val.Int)));
                
                // Handle string slicing
                if (obj == .String) {
                    const str = obj.String;
                    const end_idx = if (end_val) |ev| 
                        if (ev == .Int) @as(usize, @intCast(@min(@as(i64, @intCast(str.len)), ev.Int))) else str.len
                    else 
                        str.len;
                    
                    if (start_idx >= str.len) {
                        break :blk Value{ .String = try self.arena.allocator().dupe(u8, "") };
                    }
                    
                    const actual_end = @min(end_idx, str.len);
                    if (start_idx >= actual_end) {
                        break :blk Value{ .String = try self.arena.allocator().dupe(u8, "") };
                    }
                    
                    const slice = str[start_idx..actual_end];
                    break :blk Value{ .String = try self.arena.allocator().dupe(u8, slice) };
                }
                
                // Handle list slicing
                if (obj == .List) {
                    const list = obj.List;
                    const end_idx = if (end_val) |ev| 
                        if (ev == .Int) @as(usize, @intCast(@min(@as(i64, @intCast(list.items.len)), ev.Int))) else list.items.len
                    else 
                        list.items.len;
                    
                    var result = std.ArrayList(Value).init(self.allocator);
                    
                    if (start_idx >= list.items.len) {
                        break :blk Value{ .List = result };
                    }
                    
                    const actual_end = @min(end_idx, list.items.len);
                    if (start_idx < actual_end) {
                        for (list.items[start_idx..actual_end]) |item| {
                            try result.append(item);
                        }
                    }
                    
                    break :blk Value{ .List = result };
                }
                
                break :blk Value.None;
            },

            .MemberAccess => |v| blk: {
                // For now, just return a marker that this is a member access
                // The actual method call will be handled in FunctionCall
                _ = v;
                break :blk Value.None;
            },

            .Identifier => |v| blk: {
                // Lookup from innermost scope to outermost
                if (self.scopes.items.len > 0) {
                    var i: usize = self.scopes.items.len;
                    while (i > 0) {
                        i -= 1;
                        if (self.scopes.items[i].get(v.name)) |value| {
                            break :blk value;
                        }
                    }
                }
                // Finally check globals
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
                    // Normal variable assignment
                    if (self.scopes.items.len > 0) {
                        try self.scopes.items[self.scopes.items.len - 1].put(v.target.Identifier.name, value);
                    } else {
                        try self.globals.put(v.target.Identifier.name, value);
                    }
                } else if (v.target.* == .IndexAccess) {
                    // Index assignment: list[0] = value or dict["key"] = value
                    const index_access = v.target.IndexAccess;
                    const idx = try self.eval(index_access.index);
                    
                    // Get the actual object pointer from variable
                    if (index_access.object.* == .Identifier) {
                        const var_name = index_access.object.Identifier.name;
                        
                        // Try to get from globals (use getPtr to modify in place)
                        if (self.globals.getPtr(var_name)) |target_ptr| {
                            if (target_ptr.* == .List and idx == .Int) {
                                // List assignment
                                const index = @as(usize, @intCast(idx.Int));
                                if (index < target_ptr.List.items.len) {
                                    target_ptr.List.items[index] = value;
                                }
                            } else if (target_ptr.* == .Dict) {
                                // Dict assignment
                                const key_str = switch (idx) {
                                    .String => |s| s,
                                    .Int => |i| try std.fmt.allocPrint(self.arena.allocator(), "{}", .{i}),
                                    else => "unknown",
                                };
                                try target_ptr.Dict.put(key_str, value);
                            }
                        }
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
                self.return_value = if (v.value) |val| 
                    try self.eval(val)
                else 
                    Value.None;
                self.return_flag = true;
                break :blk Value.None;
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
                
                // Support list iteration
                if (iterable == .List) {
                    for (iterable.List.items) |item| {
                        // Set iterator variable
                        if (v.iterator.* == .Identifier) {
                            try self.globals.put(v.iterator.Identifier.name, item);
                        }
                        _ = try self.eval(v.body);
                    }
                }
                // Support range-like iteration on integers
                else if (iterable == .Int) {
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
                    if (self.return_flag) break;
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

        // String operations
        if (left_val == .String and right_val == .String) {
            if (std.mem.eql(u8, operator, "+")) {
                const concat_result = try std.fmt.allocPrint(self.arena.allocator(), "{s}{s}", .{ left_val.String, right_val.String });
                return Value{ .String = concat_result };
            }
            if (std.mem.eql(u8, operator, "==")) {
                return Value{ .Bool = std.mem.eql(u8, left_val.String, right_val.String) };
            }
            if (std.mem.eql(u8, operator, "!=")) {
                return Value{ .Bool = !std.mem.eql(u8, left_val.String, right_val.String) };
            }
        }
        
        // String multiplication: "abc" * 3 or 3 * "abc"
        if ((left_val == .String and right_val == .Int) or (left_val == .Int and right_val == .String)) {
            if (std.mem.eql(u8, operator, "*")) {
                const str = if (left_val == .String) left_val.String else right_val.String;
                const count = if (left_val == .Int) left_val.Int else right_val.Int;
                    
                if (count < 0) {
                    return Value{ .String = try self.arena.allocator().dupe(u8, "") };
                }
                    
                if (count == 0) {
                    return Value{ .String = try self.arena.allocator().dupe(u8, "") };
                }
                    
                // Calculate total length
                const total_len = str.len * @as(usize, @intCast(count));
                var result = try self.arena.allocator().alloc(u8, total_len);
                    
                // Repeat the string
                var i: usize = 0;
                while (i < count) : (i += 1) {
                    const offset = i * str.len;
                    @memcpy(result[offset..offset + str.len], str);
                }
                    
                return Value{ .String = result };
            }
        }

        std.debug.print("Type error in binary operation: {s} {s} {s}\n", .{@tagName(left_val), operator, @tagName(right_val)});
        return InterpreterError.TypeError;
    }

    fn evalFunctionCall(self: *Interpreter, callee: *Node, arguments: std.ArrayList(*Node)) !Value {
        // Check if this is a method call (callee is MemberAccess)
        if (callee.* == .MemberAccess) {
            const member_access = callee.MemberAccess;
            const method_name = member_access.member;
            
            // Evaluate all arguments
            var eval_args = std.ArrayList(Value).init(self.allocator);
            defer eval_args.deinit();
            for (arguments.items) |arg| {
                try eval_args.append(try self.eval(arg));
            }
            
            // For list methods that modify the list, we need to get the variable name
            // and modify it in place
            if (member_access.object.* == .Identifier) {
                const var_name = member_access.object.Identifier.name;
                
                // Try to get mutable reference from globals
                if (self.globals.getPtr(var_name)) |obj_ptr| {
                    // Handle list methods
                    if (obj_ptr.* == .List) {
                        return try self.callListMethod(obj_ptr, method_name, eval_args.items);
                    }
                    
                    // Handle dict methods
                    if (obj_ptr.* == .Dict) {
                        return try self.callDictMethod(obj_ptr, method_name, eval_args.items);
                    }
                }
                
                // Try from scopes
                if (self.scopes.items.len > 0) {
                    var i: usize = self.scopes.items.len;
                    while (i > 0) {
                        i -= 1;
                        if (self.scopes.items[i].getPtr(var_name)) |obj_ptr| {
                            // Handle list methods
                            if (obj_ptr.* == .List) {
                                return try self.callListMethod(obj_ptr, method_name, eval_args.items);
                            }
                            
                            // Handle dict methods
                            if (obj_ptr.* == .Dict) {
                                return try self.callDictMethod(obj_ptr, method_name, eval_args.items);
                            }
                        }
                    }
                }
            }
            
            // For non-modifying methods, evaluate the object
            const obj = try self.eval(member_access.object);
            
            // Handle string methods
            if (obj == .String) {
                return try self.callStringMethod(obj.String, method_name, eval_args.items);
            }
            
            return Value.None;
        }
        
        // Get function name
        if (callee.* != .Identifier) return Value.None;
        const name = callee.Identifier.name;

        // Evaluate all arguments first
        var eval_args = std.ArrayList(Value).init(self.allocator);
        defer eval_args.deinit();
        for (arguments.items) |arg| {
            try eval_args.append(try self.eval(arg));
        }

        // Check built-in functions
        if (builtins.builtins.get(name)) |builtin_fn| {
            return builtin_fn(self, eval_args.items);
        }

        // User-defined functions
        if (self.globals.get(name)) |func_val| {
            if (func_val == .Function) {
                return try self.callUserFunction(func_val.Function, eval_args.items);
            }
        }

        return Value.None;
    }

    fn callStringMethod(self: *Interpreter, str: []const u8, method: []const u8, args: []Value) !Value {
        if (std.mem.eql(u8, method, "upper")) {
            var result = try self.arena.allocator().alloc(u8, str.len);
            for (str, 0..) |c, i| {
                result[i] = std.ascii.toUpper(c);
            }
            return Value{ .String = result };
        }
        
        if (std.mem.eql(u8, method, "lower")) {
            var result = try self.arena.allocator().alloc(u8, str.len);
            for (str, 0..) |c, i| {
                result[i] = std.ascii.toLower(c);
            }
            return Value{ .String = result };
        }
        
        if (std.mem.eql(u8, method, "split")) {
            const delimiter = if (args.len > 0 and args[0] == .String) 
                args[0].String 
            else 
                " ";
            
            var result = std.ArrayList(Value).init(self.allocator);
            var iter = std.mem.splitSequence(u8, str, delimiter);
            while (iter.next()) |part| {
                const part_copy = try self.arena.allocator().dupe(u8, part);
                try result.append(Value{ .String = part_copy });
            }
            return Value{ .List = result };
        }
        
        if (std.mem.eql(u8, method, "strip")) {
            const trimmed = std.mem.trim(u8, str, " \t\n\r");
            return Value{ .String = try self.arena.allocator().dupe(u8, trimmed) };
        }
        
        if (std.mem.eql(u8, method, "startswith")) {
            if (args.len > 0 and args[0] == .String) {
                const prefix = args[0].String;
                return Value{ .Bool = std.mem.startsWith(u8, str, prefix) };
            }
            return Value{ .Bool = false };
        }
        
        if (std.mem.eql(u8, method, "endswith")) {
            if (args.len > 0 and args[0] == .String) {
                const suffix = args[0].String;
                return Value{ .Bool = std.mem.endsWith(u8, str, suffix) };
            }
            return Value{ .Bool = false };
        }
        
        if (std.mem.eql(u8, method, "replace")) {
            if (args.len >= 2 and args[0] == .String and args[1] == .String) {
                const old = args[0].String;
                const new = args[1].String;
                
                // Simple replace implementation
                var result = std.ArrayList(u8).init(self.arena.allocator());
                var i: usize = 0;
                while (i < str.len) {
                    if (i + old.len <= str.len and std.mem.eql(u8, str[i..i+old.len], old)) {
                        try result.appendSlice(new);
                        i += old.len;
                    } else {
                        try result.append(str[i]);
                        i += 1;
                    }
                }
                return Value{ .String = try result.toOwnedSlice() };
            }
            return Value{ .String = try self.arena.allocator().dupe(u8, str) };
        }
        
        return Value.None;
    }

    fn callListMethod(self: *Interpreter, list_ptr: *Value, method: []const u8, args: []Value) !Value {
        _ = self;
        if (list_ptr.* != .List) return Value.None;
        
        if (std.mem.eql(u8, method, "append")) {
            if (args.len > 0) {
                try list_ptr.List.append(args[0]);
            }
            return Value.None;
        }
        
        if (std.mem.eql(u8, method, "pop")) {
            if (list_ptr.List.items.len > 0) {
                const index = if (args.len > 0 and args[0] == .Int)
                    @as(usize, @intCast(args[0].Int))
                else
                    list_ptr.List.items.len - 1;
                
                if (index < list_ptr.List.items.len) {
                    const value = list_ptr.List.items[index];
                    _ = list_ptr.List.orderedRemove(index);
                    return value;
                }
            }
            return Value.None;
        }
        
        if (std.mem.eql(u8, method, "insert")) {
            if (args.len >= 2 and args[0] == .Int) {
                const index = @as(usize, @intCast(@max(0, args[0].Int)));
                const actual_index = @min(index, list_ptr.List.items.len);
                try list_ptr.List.insert(actual_index, args[1]);
            }
            return Value.None;
        }
        
        if (std.mem.eql(u8, method, "remove")) {
            if (args.len > 0) {
                // Find and remove first occurrence
                for (list_ptr.List.items, 0..) |item, i| {
                    const matches = switch (item) {
                        .Int => |v| args[0] == .Int and v == args[0].Int,
                        .String => |v| args[0] == .String and std.mem.eql(u8, v, args[0].String),
                        .Bool => |v| args[0] == .Bool and v == args[0].Bool,
                        else => false,
                    };
                    if (matches) {
                        _ = list_ptr.List.orderedRemove(i);
                        break;
                    }
                }
            }
            return Value.None;
        }
        
        if (std.mem.eql(u8, method, "clear")) {
            list_ptr.List.clearRetainingCapacity();
            return Value.None;
        }
        
        if (std.mem.eql(u8, method, "extend")) {
            if (args.len > 0 and args[0] == .List) {
                for (args[0].List.items) |item| {
                    try list_ptr.List.append(item);
                }
            }
            return Value.None;
        }
        
        if (std.mem.eql(u8, method, "count")) {
            if (args.len > 0) {
                var count: i64 = 0;
                for (list_ptr.List.items) |item| {
                    const matches = switch (item) {
                        .Int => |v| args[0] == .Int and v == args[0].Int,
                        .String => |v| args[0] == .String and std.mem.eql(u8, v, args[0].String),
                        .Bool => |v| args[0] == .Bool and v == args[0].Bool,
                        else => false,
                    };
                    if (matches) count += 1;
                }
                return Value{ .Int = count };
            }
            return Value{ .Int = 0 };
        }
        
        if (std.mem.eql(u8, method, "index")) {
            if (args.len > 0) {
                for (list_ptr.List.items, 0..) |item, i| {
                    const matches = switch (item) {
                        .Int => |v| args[0] == .Int and v == args[0].Int,
                        .String => |v| args[0] == .String and std.mem.eql(u8, v, args[0].String),
                        .Bool => |v| args[0] == .Bool and v == args[0].Bool,
                        else => false,
                    };
                    if (matches) {
                        return Value{ .Int = @as(i64, @intCast(i)) };
                    }
                }
            }
            return Value{ .Int = -1 };
        }
        
        if (std.mem.eql(u8, method, "reverse")) {
            std.mem.reverse(Value, list_ptr.List.items);
            return Value.None;
        }
        
        if (std.mem.eql(u8, method, "sort")) {
            // Simple bubble sort for now
            const items = list_ptr.List.items;
            if (items.len <= 1) return Value.None;
            
            var i: usize = 0;
            while (i < items.len - 1) : (i += 1) {
                var j: usize = 0;
                while (j < items.len - 1 - i) : (j += 1) {
                    const should_swap = switch (items[j]) {
                        .Int => |a| items[j + 1] == .Int and a > items[j + 1].Int,
                        .String => |a| items[j + 1] == .String and std.mem.order(u8, a, items[j + 1].String) == .gt,
                        else => false,
                    };
                    if (should_swap) {
                        const temp = items[j];
                        items[j] = items[j + 1];
                        items[j + 1] = temp;
                    }
                }
            }
            return Value.None;
        }
        
        return Value.None;
    }

    fn callDictMethod(self: *Interpreter, dict_ptr: *Value, method: []const u8, args: []Value) !Value {
        if (dict_ptr.* != .Dict) return Value.None;
        
        if (std.mem.eql(u8, method, "keys")) {
            var result = std.ArrayList(Value).init(self.allocator);
            var iter = dict_ptr.Dict.keyIterator();
            while (iter.next()) |key| {
                try result.append(Value{ .String = key.* });
            }
            return Value{ .List = result };
        }
        
        if (std.mem.eql(u8, method, "values")) {
            var result = std.ArrayList(Value).init(self.allocator);
            var iter = dict_ptr.Dict.valueIterator();
            while (iter.next()) |value| {
                try result.append(value.*);
            }
            return Value{ .List = result };
        }
        
        if (std.mem.eql(u8, method, "items")) {
            var result = std.ArrayList(Value).init(self.allocator);
            var iter = dict_ptr.Dict.iterator();
            while (iter.next()) |entry| {
                var pair = std.ArrayList(Value).init(self.allocator);
                try pair.append(Value{ .String = entry.key_ptr.* });
                try pair.append(entry.value_ptr.*);
                try result.append(Value{ .List = pair });
            }
            return Value{ .List = result };
        }
        
        if (std.mem.eql(u8, method, "get")) {
            if (args.len > 0 and args[0] == .String) {
                const key = args[0].String;
                if (dict_ptr.Dict.get(key)) |value| {
                    return value;
                }
                // Return default value if provided
                if (args.len > 1) {
                    return args[1];
                }
            }
            return Value.None;
        }
        
        if (std.mem.eql(u8, method, "clear")) {
            dict_ptr.Dict.clearRetainingCapacity();
            return Value.None;
        }
        
        if (std.mem.eql(u8, method, "pop")) {
            if (args.len > 0 and args[0] == .String) {
                const key = args[0].String;
                if (dict_ptr.Dict.fetchRemove(key)) |kv| {
                    return kv.value;
                }
                // Return default value if provided
                if (args.len > 1) {
                    return args[1];
                }
            }
            return Value.None;
        }
        
        if (std.mem.eql(u8, method, "update")) {
            if (args.len > 0 and args[0] == .Dict) {
                var iter = args[0].Dict.iterator();
                while (iter.next()) |entry| {
                    try dict_ptr.Dict.put(entry.key_ptr.*, entry.value_ptr.*);
                }
            }
            return Value.None;
        }
        
        return Value.None;
    }

    fn callUserFunction(self: *Interpreter, func: anytype, args: []Value) !Value {
        // Push new scope
        var local_scope = std.StringHashMap(Value).init(self.allocator);
        try self.scopes.append(local_scope);
        defer {
            _ = self.scopes.pop();
            local_scope.deinit();
        }

        // Bind parameters to current scope
        for (func.params.items, 0..) |param, i| {
            if (param.* == .Identifier) {
                const arg_val = if (i < args.len) args[i] else Value.None;
                try self.scopes.items[self.scopes.items.len - 1].put(param.Identifier.name, arg_val);
            }
        }

        // Execute function body
        const prev_return_flag = self.return_flag;
        self.return_flag = false;
        
        _ = try self.eval(func.body);
        
        // Get return value and restore state
        const result = self.return_value;
        self.return_flag = prev_return_flag;
        
        return result;
    }

    pub fn registerBuiltin(self: *Interpreter, name: []const u8) !void {
        // Built-ins are handled directly in evalFunctionCall
        _ = self;
        _ = name;
    }
};
