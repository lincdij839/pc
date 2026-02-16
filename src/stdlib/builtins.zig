// PC Language Standard Library - Built-in Functions
const std = @import("std");
const Interpreter = @import("../interpreter.zig").Interpreter;
const Value = @import("../interpreter.zig").Value;
const InterpreterError = @import("../interpreter.zig").InterpreterError;
const string_utils = @import("string_utils.zig");
const sys_io = @import("sys_io.zig");
const linux_pkg = @import("linux/package.zig");
const linux_systemd = @import("linux/systemd.zig");
const linux_remote = @import("linux/remote.zig");

// Function signature for all built-in functions
pub const BuiltinFn = *const fn (*Interpreter, []Value) InterpreterError!Value;

// Built-in function map
pub const builtins = std.StaticStringMap(BuiltinFn).initComptime(.{
    .{ "print", builtin_print },
    .{ "len", builtin_len },
    .{ "range", builtin_range },
    .{ "str", builtin_str },
    .{ "int", builtin_int },
    .{ "float", builtin_float },
    .{ "bool", builtin_bool },
    .{ "type", builtin_type },
    .{ "abs", builtin_abs },
    .{ "max", builtin_max },
    .{ "min", builtin_min },
    .{ "pow", builtin_pow },
    .{ "sum", builtin_sum },
    .{ "sorted", builtin_sorted },
    .{ "reversed", builtin_reversed },
    .{ "upper", builtin_upper },
    .{ "lower", builtin_lower },
    .{ "append", builtin_append },
    .{ "pop", builtin_pop },
    .{ "insert", builtin_insert },
    .{ "remove", builtin_remove },
    .{ "keys", builtin_keys },
    .{ "values", builtin_values },
    .{ "items", builtin_items },
    // String utilities
    .{ "split", string_utils.builtin_split },
    .{ "join", string_utils.builtin_join },
    .{ "replace", string_utils.builtin_replace },
    .{ "strip", string_utils.builtin_strip },
    .{ "startswith", string_utils.builtin_startswith },
    .{ "endswith", string_utils.builtin_endswith },
    .{ "find", string_utils.builtin_find },
    .{ "chr", string_utils.builtin_chr },
    .{ "ord", string_utils.builtin_ord },
    .{ "bin", string_utils.builtin_bin },
    .{ "oct", string_utils.builtin_oct },
    .{ "unhex", string_utils.builtin_unhex },
    // System I/O functions
    .{ "read_file", sys_io.builtin_read_file },
    .{ "write_file", sys_io.builtin_write_file },
    .{ "file_exists", sys_io.builtin_file_exists },
    .{ "file_size", sys_io.builtin_file_size },
    .{ "list_dir", sys_io.builtin_list_dir },
    .{ "exec", sys_io.builtin_exec },
    .{ "getenv", sys_io.builtin_getenv },
    .{ "setenv", sys_io.builtin_setenv },
    .{ "http_get", sys_io.builtin_http_get },
    .{ "tcp_connect", sys_io.builtin_tcp_connect },
    .{ "os_name", sys_io.builtin_os_name },
    .{ "arch", sys_io.builtin_arch },
    .{ "cwd", sys_io.builtin_cwd },
    .{ "sleep", sys_io.builtin_sleep },
    .{ "timestamp", sys_io.builtin_timestamp },
    // Linux Package Management
    .{ "distro", linux_pkg.builtin_distro },
    .{ "distro_version", linux_pkg.builtin_distro_version },
    .{ "pkg_manager", linux_pkg.builtin_pkg_manager },
    .{ "pkg_install", linux_pkg.builtin_pkg_install },
    .{ "pkg_remove", linux_pkg.builtin_pkg_remove },
    .{ "pkg_update", linux_pkg.builtin_pkg_update },
    .{ "pkg_upgrade", linux_pkg.builtin_pkg_upgrade },
    .{ "pkg_search", linux_pkg.builtin_pkg_search },
    .{ "pkg_list_installed", linux_pkg.builtin_pkg_list_installed },
    .{ "pkg_info", linux_pkg.builtin_pkg_info },
    // Linux systemd Service Management
    .{ "service_start", linux_systemd.builtin_service_start },
    .{ "service_stop", linux_systemd.builtin_service_stop },
    .{ "service_restart", linux_systemd.builtin_service_restart },
    .{ "service_reload", linux_systemd.builtin_service_reload },
    .{ "service_enable", linux_systemd.builtin_service_enable },
    .{ "service_disable", linux_systemd.builtin_service_disable },
    .{ "service_status", linux_systemd.builtin_service_status },
    .{ "service_is_enabled", linux_systemd.builtin_service_is_enabled },
    .{ "service_list", linux_systemd.builtin_service_list },
    // Remote System Management (多系统互联)
    .{ "ssh_connect", linux_remote.builtin_ssh_connect },
    .{ "ssh_exec", linux_remote.builtin_ssh_exec },
    .{ "ssh_copy", linux_remote.builtin_ssh_copy },
    .{ "ssh_download", linux_remote.builtin_ssh_download },
    .{ "remote_distro", linux_remote.builtin_remote_distro },
    .{ "remote_pkg_install", linux_remote.builtin_remote_pkg_install },
    .{ "sync_file", linux_remote.builtin_sync_file },
    .{ "service_logs", linux_systemd.builtin_service_logs },
});

// ============================================================================
// Built-in Function Implementations
// ============================================================================

// print(*args) - Output to stdout
fn builtin_print(interp: *Interpreter, args: []Value) InterpreterError!Value {
    for (args) |arg| {
        try interp.stdout.print("{}", .{arg});
    }
    try interp.stdout.print("\n", .{});
    return Value.None;
}

// len(obj) - Return length of string or list
fn builtin_len(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0) return Value{ .Int = 0 };
    return switch (args[0]) {
        .String => |s| Value{ .Int = @intCast(s.len) },
        .List => |l| Value{ .Int = @intCast(l.items.len) },
        .Dict => |d| Value{ .Int = @intCast(d.count()) },
        else => Value{ .Int = 0 },
    };
}

// range(n) - Return max value for iteration
fn builtin_range(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0) return Value{ .Int = 0 };
    return switch (args[0]) {
        .Int => args[0],
        else => Value{ .Int = 0 },
    };
}

// str(x) - Convert to string
fn builtin_str(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0) return Value{ .String = "" };
    
    const str_val = switch (args[0]) {
        .Int => |i| try std.fmt.allocPrint(interp.allocator, "{}", .{i}),
        .Float => |f| try std.fmt.allocPrint(interp.allocator, "{d}", .{f}),
        .Bool => |b| if (b) "true" else "false",
        .String => |s| s,
        .None => "None",
        else => "<object>",
    };
    return Value{ .String = str_val };
}

// int(x) - Convert to integer
fn builtin_int(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0) return Value{ .Int = 0 };
    
    const int_val = switch (args[0]) {
        .Int => |i| i,
        .Float => |f| @as(i64, @intFromFloat(f)),
        .Bool => |b| if (b) @as(i64, 1) else @as(i64, 0),
        .String => |s| std.fmt.parseInt(i64, s, 10) catch 0,
        else => 0,
    };
    return Value{ .Int = int_val };
}

// float(x) - Convert to float
fn builtin_float(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0) return Value{ .Float = 0.0 };
    
    const float_val = switch (args[0]) {
        .Int => |i| @as(f64, @floatFromInt(i)),
        .Float => |f| f,
        .Bool => |b| if (b) @as(f64, 1.0) else @as(f64, 0.0),
        .String => |s| std.fmt.parseFloat(f64, s) catch 0.0,
        else => 0.0,
    };
    return Value{ .Float = float_val };
}

// bool(x) - Convert to boolean
fn builtin_bool(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0) return Value{ .Bool = false };
    
    const bool_val = switch (args[0]) {
        .Int => |i| i != 0,
        .Float => |f| f != 0.0,
        .Bool => |b| b,
        .String => |s| s.len > 0,
        .None => false,
        .List => |l| l.items.len > 0,
        .Dict => |d| d.count() > 0,
        else => false,
    };
    return Value{ .Bool = bool_val };
}

// type(x) - Return type name
fn builtin_type(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0) return Value{ .String = "none" };
    
    const type_name = switch (args[0]) {
        .Int => "int",
        .Float => "float",
        .Bool => "bool",
        .String => "str",
        .None => "none",
        .List => "list",
        .Dict => "dict",
        .Function => "function",
    };
    
    const result = try interp.allocator.dupe(u8, type_name);
    return Value{ .String = result };
}

// sum(list) - Sum of list elements
fn builtin_sum(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .List) return Value{ .Int = 0 };
    
    var sum_int: i64 = 0;
    var sum_float: f64 = 0.0;
    var has_float = false;
    
    for (args[0].List.items) |item| {
        switch (item) {
            .Int => |i| {
                if (has_float) {
                    sum_float += @floatFromInt(i);
                } else {
                    sum_int += i;
                }
            },
            .Float => |f| {
                if (!has_float) {
                    sum_float = @floatFromInt(sum_int);
                    has_float = true;
                }
                sum_float += f;
            },
            else => {},
        }
    }
    
    if (has_float) {
        return Value{ .Float = sum_float };
    } else {
        return Value{ .Int = sum_int };
    }
}

// sorted(list) - Return sorted list
fn builtin_sorted(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .List) return Value.None;
    
    var new_list = std.ArrayList(Value).init(interp.allocator);
    try new_list.appendSlice(args[0].List.items);
    
    // Simple bubble sort for integers
    var i: usize = 0;
    while (i < new_list.items.len) : (i += 1) {
        var j: usize = 0;
        while (j < new_list.items.len - 1 - i) : (j += 1) {
            if (new_list.items[j] == .Int and new_list.items[j + 1] == .Int) {
                if (new_list.items[j].Int > new_list.items[j + 1].Int) {
                    const temp = new_list.items[j];
                    new_list.items[j] = new_list.items[j + 1];
                    new_list.items[j + 1] = temp;
                }
            }
        }
    }
    
    return Value{ .List = new_list };
}

// reversed(list) - Return reversed list
fn builtin_reversed(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .List) return Value.None;
    
    var new_list = std.ArrayList(Value).init(interp.allocator);
    var i: usize = args[0].List.items.len;
    while (i > 0) {
        i -= 1;
        try new_list.append(args[0].List.items[i]);
    }
    
    return Value{ .List = new_list };
}

// pop(list, index) - Remove and return item at index
fn builtin_pop(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .List) return Value.None;
    
    const index = if (args.len > 1 and args[1] == .Int) 
        args[1].Int 
    else 
        @as(i64, @intCast(args[0].List.items.len)) - 1;
    
    if (index < 0 or index >= args[0].List.items.len) {
        return Value.None;
    }
    
    const value = args[0].List.items[@intCast(index)];
    _ = args[0].List.orderedRemove(@intCast(index));
    return value;
}

// insert(list, index, value) - Insert value at index
fn builtin_insert(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len < 3 or args[0] != .List or args[1] != .Int) {
        return Value.None;
    }
    
    const index = args[1].Int;
    if (index < 0 or index > args[0].List.items.len) {
        return Value.None;
    }
    
    args[0].List.insert(@intCast(index), args[2]) catch {
        return Value.None;
    };
    
    return Value.None;
}

// remove(list, value) - Remove first occurrence of value
fn builtin_remove(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len < 2 or args[0] != .List) return Value.None;
    
    for (args[0].List.items, 0..) |item, i| {
        // Simple equality check for Int and String
        const equal = switch (item) {
            .Int => |iv| if (args[1] == .Int) iv == args[1].Int else false,
            .String => |sv| if (args[1] == .String) std.mem.eql(u8, sv, args[1].String) else false,
            else => false,
        };
        
        if (equal) {
            _ = args[0].List.orderedRemove(i);
            break;
        }
    }
    
    return Value.None;
}

// items(dict) - Return list of (key, value) tuples
fn builtin_items(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .Dict) return Value.None;
    
    var items_list = std.ArrayList(Value).init(interp.allocator);
    var it = args[0].Dict.iterator();
    while (it.next()) |entry| {
        var pair = std.ArrayList(Value).init(interp.allocator);
        try pair.append(Value{ .String = entry.key_ptr.* });
        try pair.append(entry.value_ptr.*);
        try items_list.append(Value{ .List = pair });
    }
    return Value{ .List = items_list };
}

// abs(x) - Absolute value
fn builtin_abs(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0) return Value{ .Int = 0 };
    
    return switch (args[0]) {
        .Int => |i| Value{ .Int = if (i < 0) -i else i },
        .Float => |f| Value{ .Float = @abs(f) },
        else => Value{ .Int = 0 },
    };
}

// max(a, b) - Maximum of two values
fn builtin_max(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len < 2) return Value{ .Int = 0 };
    if (args[0] != .Int or args[1] != .Int) return Value{ .Int = 0 };
    
    return Value{ .Int = @max(args[0].Int, args[1].Int) };
}

// min(a, b) - Minimum of two values
fn builtin_min(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len < 2) return Value{ .Int = 0 };
    if (args[0] != .Int or args[1] != .Int) return Value{ .Int = 0 };
    
    return Value{ .Int = @min(args[0].Int, args[1].Int) };
}

// pow(base, exp) - Power function
fn builtin_pow(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len < 2) return Value{ .Int = 0 };
    if (args[0] != .Int or args[1] != .Int) return Value{ .Int = 0 };
    
    const result = std.math.pow(f64, @floatFromInt(args[0].Int), @floatFromInt(args[1].Int));
    return Value{ .Float = result };
}

// upper(s) - Convert string to uppercase
fn builtin_upper(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) return Value{ .String = "" };
    
    const result = try interp.allocator.alloc(u8, args[0].String.len);
    for (args[0].String, 0..) |c, i| {
        result[i] = std.ascii.toUpper(c);
    }
    return Value{ .String = result };
}

// lower(s) - Convert string to lowercase
fn builtin_lower(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) return Value{ .String = "" };
    
    const result = try interp.allocator.alloc(u8, args[0].String.len);
    for (args[0].String, 0..) |c, i| {
        result[i] = std.ascii.toLower(c);
    }
    return Value{ .String = result };
}

// append(list, value) - Return new list with value appended
fn builtin_append(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len != 2) return Value.None;
    if (args[0] != .List) return Value.None;
    
    // Create new list with appended value
    var new_list = std.ArrayList(Value).init(interp.allocator);
    try new_list.appendSlice(args[0].List.items);
    try new_list.append(args[1]);
    return Value{ .List = new_list };
}

// keys(dict) - Return list of dictionary keys
fn builtin_keys(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .Dict) return Value.None;
    
    var key_list = std.ArrayList(Value).init(interp.allocator);
    var it = args[0].Dict.keyIterator();
    while (it.next()) |key| {
        try key_list.append(Value{ .String = key.* });
    }
    return Value{ .List = key_list };
}

// values(dict) - Return list of dictionary values
fn builtin_values(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .Dict) return Value.None;
    
    var val_list = std.ArrayList(Value).init(interp.allocator);
    var it = args[0].Dict.valueIterator();
    while (it.next()) |val| {
        try val_list.append(val.*);
    }
    return Value{ .List = val_list };
}
