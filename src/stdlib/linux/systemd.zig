// PC Language - systemd Service Management
// systemd 服务管理接口
const std = @import("std");
const Interpreter = @import("../../interpreter.zig").Interpreter;
const Value = @import("../../interpreter.zig").Value;
const InterpreterError = @import("../../interpreter.zig").InterpreterError;

/// 执行 systemctl 命令
fn systemctl(allocator: std.mem.Allocator, args: []const []const u8) ![]const u8 {
    var argv = std.ArrayList([]const u8).init(allocator);
    defer argv.deinit();
    
    try argv.append("systemctl");
    for (args) |arg| {
        try argv.append(arg);
    }
    
    var child = std.process.Child.init(argv.items, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    
    try child.spawn();
    
    const stdout = try child.stdout.?.readToEndAlloc(allocator, 10 * 1024 * 1024);
    errdefer allocator.free(stdout);
    
    const stderr = try child.stderr.?.readToEndAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(stderr);
    
    _ = try child.wait();
    
    return stdout;
}

// ============================================================================
// systemd 服务管理函数
// ============================================================================

/// service_start(name) - 启动服务
pub fn builtin_service_start(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .Bool = false };
    }
    
    const service = args[0].String;
    const cmd_args = [_][]const u8{ "start", service };
    
    const output = systemctl(interp.allocator, &cmd_args) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(output);
    
    return Value{ .Bool = true };
}

/// service_stop(name) - 停止服务
pub fn builtin_service_stop(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .Bool = false };
    }
    
    const service = args[0].String;
    const cmd_args = [_][]const u8{ "stop", service };
    
    const output = systemctl(interp.allocator, &cmd_args) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(output);
    
    return Value{ .Bool = true };
}

/// service_restart(name) - 重启服务
pub fn builtin_service_restart(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .Bool = false };
    }
    
    const service = args[0].String;
    const cmd_args = [_][]const u8{ "restart", service };
    
    const output = systemctl(interp.allocator, &cmd_args) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(output);
    
    return Value{ .Bool = true };
}

/// service_reload(name) - 重新加载服务配置
pub fn builtin_service_reload(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .Bool = false };
    }
    
    const service = args[0].String;
    const cmd_args = [_][]const u8{ "reload", service };
    
    const output = systemctl(interp.allocator, &cmd_args) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(output);
    
    return Value{ .Bool = true };
}

/// service_enable(name) - 启用服务（开机自启）
pub fn builtin_service_enable(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .Bool = false };
    }
    
    const service = args[0].String;
    const cmd_args = [_][]const u8{ "enable", service };
    
    const output = systemctl(interp.allocator, &cmd_args) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(output);
    
    return Value{ .Bool = true };
}

/// service_disable(name) - 禁用服务
pub fn builtin_service_disable(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .Bool = false };
    }
    
    const service = args[0].String;
    const cmd_args = [_][]const u8{ "disable", service };
    
    const output = systemctl(interp.allocator, &cmd_args) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(output);
    
    return Value{ .Bool = true };
}

/// service_status(name) - 获取服务状态
pub fn builtin_service_status(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = try interp.allocator.dupe(u8, "unknown") };
    }
    
    const service = args[0].String;
    const cmd_args = [_][]const u8{ "is-active", service };
    
    const output = systemctl(interp.allocator, &cmd_args) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "unknown") };
    };
    
    // 去除换行符
    const status = std.mem.trim(u8, output, "\n\r ");
    const result = try interp.allocator.dupe(u8, status);
    interp.allocator.free(output);
    
    return Value{ .String = result };
}

/// service_is_enabled(name) - 检查服务是否启用
pub fn builtin_service_is_enabled(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .Bool = false };
    }
    
    const service = args[0].String;
    const cmd_args = [_][]const u8{ "is-enabled", service };
    
    const output = systemctl(interp.allocator, &cmd_args) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(output);
    
    const status = std.mem.trim(u8, output, "\n\r ");
    return Value{ .Bool = std.mem.eql(u8, status, "enabled") };
}

/// service_list() - 列出所有服务
pub fn builtin_service_list(interp: *Interpreter, _: []Value) InterpreterError!Value {
    const cmd_args = [_][]const u8{ "list-units", "--type=service", "--all", "--no-pager" };
    
    const output = systemctl(interp.allocator, &cmd_args) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    };
    
    return Value{ .String = output };
}

/// service_logs(name, lines) - 获取服务日志
pub fn builtin_service_logs(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    }
    
    const service = args[0].String;
    const lines = if (args.len > 1 and args[1] == .Int) args[1].Int else 100;
    
    var argv = std.ArrayList([]const u8).init(interp.allocator);
    defer argv.deinit();
    
    try argv.append("journalctl");
    try argv.append("-u");
    try argv.append(service);
    try argv.append("-n");
    
    const lines_str = try std.fmt.allocPrint(interp.allocator, "{}", .{lines});
    defer interp.allocator.free(lines_str);
    try argv.append(lines_str);
    try argv.append("--no-pager");
    
    var child = std.process.Child.init(argv.items, interp.allocator);
    child.stdout_behavior = .Pipe;
    
    child.spawn() catch {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    };
    
    const output = child.stdout.?.readToEndAlloc(interp.allocator, 10 * 1024 * 1024) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    };
    _ = child.wait() catch {};
    
    return Value{ .String = output };
}
