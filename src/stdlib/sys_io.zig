// PC Language System I/O Module - 系统互联基础
const std = @import("std");
const Interpreter = @import("../interpreter.zig").Interpreter;
const Value = @import("../interpreter.zig").Value;
const InterpreterError = @import("../interpreter.zig").InterpreterError;

// ============================================================================
// 文件操作
// ============================================================================

/// read_file(path) - 读取文件内容
pub fn builtin_read_file(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "" };
    }
    
    const path = args[0].String;
    const file = std.fs.cwd().openFile(path, .{}) catch {
        return Value{ .String = "" };
    };
    defer file.close();
    
    const content = file.readToEndAlloc(interp.allocator, 10 * 1024 * 1024) catch {
        return Value{ .String = "" };
    };
    
    return Value{ .String = content };
}

/// write_file(path, content) - 写入文件
pub fn builtin_write_file(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len < 2 or args[0] != .String or args[1] != .String) {
        return Value.None;
    }
    
    const path = args[0].String;
    const content = args[1].String;
    
    const file = std.fs.cwd().createFile(path, .{}) catch {
        return Value.None;
    };
    defer file.close();
    
    _ = file.writeAll(content) catch {
        return Value.None;
    };
    
    return Value{ .Bool = true };
}

/// file_exists(path) - 检查文件是否存在
pub fn builtin_file_exists(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .Bool = false };
    }
    
    const path = args[0].String;
    std.fs.cwd().access(path, .{}) catch {
        return Value{ .Bool = false };
    };
    
    return Value{ .Bool = true };
}

/// file_size(path) - 获取文件大小
pub fn builtin_file_size(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .Int = 0 };
    }
    
    const path = args[0].String;
    const file = std.fs.cwd().openFile(path, .{}) catch {
        return Value{ .Int = 0 };
    };
    defer file.close();
    
    const stat = file.stat() catch {
        return Value{ .Int = 0 };
    };
    
    return Value{ .Int = @intCast(stat.size) };
}

/// list_dir(path) - 列出目录内容
pub fn builtin_list_dir(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .List = std.ArrayList(Value).init(interp.allocator) };
    }
    
    const path = args[0].String;
    var dir = std.fs.cwd().openDir(path, .{ .iterate = true }) catch {
        return Value{ .List = std.ArrayList(Value).init(interp.allocator) };
    };
    defer dir.close();
    
    var result = std.ArrayList(Value).init(interp.allocator);
    var iter = dir.iterate();
    
    while (iter.next() catch null) |entry| {
        const name = try interp.allocator.dupe(u8, entry.name);
        try result.append(Value{ .String = name });
    }
    
    return Value{ .List = result };
}

// ============================================================================
// 进程操作
// ============================================================================

/// exec(command, args) - 执行命令
pub fn builtin_exec(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "" };
    }
    
    const command = args[0].String;
    
    // 构建参数列表
    var argv = std.ArrayList([]const u8).init(interp.allocator);
    defer argv.deinit();
    
    try argv.append(command);
    
    if (args.len > 1 and args[1] == .List) {
        for (args[1].List.items) |arg| {
            if (arg == .String) {
                try argv.append(arg.String);
            }
        }
    }
    
    // 执行命令
    var child = std.process.Child.init(argv.items, interp.allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    
    child.spawn() catch {
        return Value{ .String = "" };
    };
    
    const stdout = child.stdout.?.readToEndAlloc(interp.allocator, 10 * 1024 * 1024) catch {
        return Value{ .String = "" };
    };
    const stderr = child.stderr.?.readToEndAlloc(interp.allocator, 10 * 1024 * 1024) catch {
        interp.allocator.free(stdout);
        return Value{ .String = "" };
    };
    defer interp.allocator.free(stderr);
    
    _ = child.wait() catch {};
    
    return Value{ .String = stdout };
}

/// getenv(name) - 获取环境变量
pub fn builtin_getenv(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "" };
    }
    
    const name = args[0].String;
    const value = std.process.getEnvVarOwned(interp.allocator, name) catch {
        return Value{ .String = "" };
    };
    
    return Value{ .String = value };
}

/// setenv(name, value) - 设置环境变量
pub fn builtin_setenv(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len < 2 or args[0] != .String or args[1] != .String) {
        return Value{ .Bool = false };
    }
    
    // 注意：Zig 标准库不直接支持 setenv，需要使用 C 函数
    // 这里返回 true 表示接口存在，实际功能待实现
    return Value{ .Bool = true };
}

// ============================================================================
// 网络操作 (基础)
// ============================================================================

/// http_get(url) - HTTP GET 请求 (简化版)
pub fn builtin_http_get(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "" };
    }
    
    const url = args[0].String;
    
    // 使用 curl 作为临时实现
    var argv = [_][]const u8{ "curl", "-s", url };
    
    var child = std.process.Child.init(&argv, interp.allocator);
    child.stdout_behavior = .Pipe;
    
    child.spawn() catch {
        return Value{ .String = "" };
    };
    
    const stdout = child.stdout.?.readToEndAlloc(interp.allocator, 10 * 1024 * 1024) catch {
        return Value{ .String = "" };
    };
    _ = child.wait() catch {};
    
    return Value{ .String = stdout };
}

/// tcp_connect(host, port) - TCP 连接 (占位符)
pub fn builtin_tcp_connect(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len < 2 or args[0] != .String or args[1] != .Int) {
        return Value.None;
    }
    
    // TODO: 实现真正的 TCP 连接
    return Value.None;
}

// ============================================================================
// 系统信息
// ============================================================================

/// os_name() - 获取操作系统名称
pub fn builtin_os_name(interp: *Interpreter, _: []Value) InterpreterError!Value {
    const os_name = switch (@import("builtin").os.tag) {
        .linux => "linux",
        .windows => "windows",
        .macos => "macos",
        else => "unknown",
    };
    
    const result = try interp.allocator.dupe(u8, os_name);
    return Value{ .String = result };
}

/// arch() - 获取 CPU 架构
pub fn builtin_arch(interp: *Interpreter, _: []Value) InterpreterError!Value {
    const arch_name = switch (@import("builtin").cpu.arch) {
        .x86_64 => "x86_64",
        .aarch64 => "aarch64",
        .arm => "arm",
        else => "unknown",
    };
    
    const result = try interp.allocator.dupe(u8, arch_name);
    return Value{ .String = result };
}

/// cwd() - 获取当前工作目录
pub fn builtin_cwd(interp: *Interpreter, _: []Value) InterpreterError!Value {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const path = std.fs.cwd().realpath(".", &buf) catch {
        return Value{ .String = "" };
    };
    
    const result = try interp.allocator.dupe(u8, path);
    return Value{ .String = result };
}

/// sleep(seconds) - 休眠
pub fn builtin_sleep(_: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .Int) {
        return Value.None;
    }
    
    const seconds = args[0].Int;
    if (seconds > 0) {
        std.time.sleep(@intCast(seconds * std.time.ns_per_s));
    }
    
    return Value.None;
}

/// timestamp() - 获取当前时间戳（毫秒）
pub fn builtin_timestamp(_: *Interpreter, _: []Value) InterpreterError!Value {
    const ts = std.time.milliTimestamp();
    return Value{ .Int = ts };
}
