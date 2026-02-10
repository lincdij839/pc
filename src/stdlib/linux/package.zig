// PC Language - Linux Package Manager Unified Interface
// 统一的包管理器接口，支持 apt/dnf/pacman/yum
const std = @import("std");
const Interpreter = @import("../../interpreter.zig").Interpreter;
const Value = @import("../../interpreter.zig").Value;
const InterpreterError = @import("../../interpreter.zig").InterpreterError;

/// 检测当前系统的发行版
fn detectDistro(allocator: std.mem.Allocator) ![]const u8 {
    // 读取 /etc/os-release
    const file = std.fs.openFileAbsolute("/etc/os-release", .{}) catch {
        return try allocator.dupe(u8, "unknown");
    };
    defer file.close();
    
    const content = try file.readToEndAlloc(allocator, 4096);
    defer allocator.free(content);
    
    // 解析 ID= 行
    var lines = std.mem.split(u8, content, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "ID=")) {
            const id = std.mem.trim(u8, line[3..], "\"");
            return try allocator.dupe(u8, id);
        }
    }
    
    return try allocator.dupe(u8, "unknown");
}

/// 检测包管理器类型
fn detectPackageManager(allocator: std.mem.Allocator) ![]const u8 {
    const distro = try detectDistro(allocator);
    defer allocator.free(distro);
    
    if (std.mem.eql(u8, distro, "kali") or 
        std.mem.eql(u8, distro, "debian") or 
        std.mem.eql(u8, distro, "ubuntu")) {
        return try allocator.dupe(u8, "apt");
    } else if (std.mem.eql(u8, distro, "fedora") or 
               std.mem.eql(u8, distro, "rhel") or
               std.mem.eql(u8, distro, "centos")) {
        return try allocator.dupe(u8, "dnf");
    } else if (std.mem.eql(u8, distro, "arch") or 
               std.mem.eql(u8, distro, "manjaro")) {
        return try allocator.dupe(u8, "pacman");
    }
    
    return try allocator.dupe(u8, "unknown");
}

/// 执行命令并返回输出
fn execCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]const u8 {
    var child = std.process.Child.init(argv, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    
    try child.spawn();
    
    const stdout = try child.stdout.?.readToEndAlloc(allocator, 10 * 1024 * 1024);
    errdefer allocator.free(stdout);
    
    const stderr = try child.stderr.?.readToEndAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(stderr);
    
    const term = try child.wait();
    
    if (term.Exited != 0) {
        allocator.free(stdout);
        return error.CommandFailed;
    }
    
    return stdout;
}

// ============================================================================
// 包管理器函数
// ============================================================================

/// distro() - 获取发行版名称
pub fn builtin_distro(interp: *Interpreter, _: []Value) InterpreterError!Value {
    const distro = detectDistro(interp.allocator) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "unknown") };
    };
    return Value{ .String = distro };
}

/// distro_version() - 获取发行版版本
pub fn builtin_distro_version(interp: *Interpreter, _: []Value) InterpreterError!Value {
    const file = std.fs.openFileAbsolute("/etc/os-release", .{}) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "unknown") };
    };
    defer file.close();
    
    const content = file.readToEndAlloc(interp.allocator, 4096) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "unknown") };
    };
    defer interp.allocator.free(content);
    
    var lines = std.mem.split(u8, content, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "VERSION_ID=")) {
            const version = std.mem.trim(u8, line[11..], "\"");
            return Value{ .String = try interp.allocator.dupe(u8, version) };
        }
    }
    
    return Value{ .String = try interp.allocator.dupe(u8, "unknown") };
}

/// pkg_manager() - 获取包管理器类型
pub fn builtin_pkg_manager(interp: *Interpreter, _: []Value) InterpreterError!Value {
    const pm = detectPackageManager(interp.allocator) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "unknown") };
    };
    return Value{ .String = pm };
}

/// pkg_install(package) - 安装软件包
pub fn builtin_pkg_install(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .Bool = false };
    }
    
    const package = args[0].String;
    const pm = detectPackageManager(interp.allocator) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(pm);
    
    var argv = std.ArrayList([]const u8).init(interp.allocator);
    defer argv.deinit();
    
    if (std.mem.eql(u8, pm, "apt")) {
        try argv.append("sudo");
        try argv.append("apt");
        try argv.append("install");
        try argv.append("-y");
        try argv.append(package);
    } else if (std.mem.eql(u8, pm, "dnf")) {
        try argv.append("sudo");
        try argv.append("dnf");
        try argv.append("install");
        try argv.append("-y");
        try argv.append(package);
    } else if (std.mem.eql(u8, pm, "pacman")) {
        try argv.append("sudo");
        try argv.append("pacman");
        try argv.append("-S");
        try argv.append("--noconfirm");
        try argv.append(package);
    } else {
        return Value{ .Bool = false };
    }
    
    const output = execCommand(interp.allocator, argv.items) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(output);
    
    return Value{ .Bool = true };
}

/// pkg_remove(package) - 卸载软件包
pub fn builtin_pkg_remove(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .Bool = false };
    }
    
    const package = args[0].String;
    const pm = detectPackageManager(interp.allocator) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(pm);
    
    var argv = std.ArrayList([]const u8).init(interp.allocator);
    defer argv.deinit();
    
    if (std.mem.eql(u8, pm, "apt")) {
        try argv.append("sudo");
        try argv.append("apt");
        try argv.append("remove");
        try argv.append("-y");
        try argv.append(package);
    } else if (std.mem.eql(u8, pm, "dnf")) {
        try argv.append("sudo");
        try argv.append("dnf");
        try argv.append("remove");
        try argv.append("-y");
        try argv.append(package);
    } else if (std.mem.eql(u8, pm, "pacman")) {
        try argv.append("sudo");
        try argv.append("pacman");
        try argv.append("-R");
        try argv.append("--noconfirm");
        try argv.append(package);
    } else {
        return Value{ .Bool = false };
    }
    
    const output = execCommand(interp.allocator, argv.items) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(output);
    
    return Value{ .Bool = true };
}

/// pkg_update() - 更新软件包列表
pub fn builtin_pkg_update(interp: *Interpreter, _: []Value) InterpreterError!Value {
    const pm = detectPackageManager(interp.allocator) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(pm);
    
    var argv = std.ArrayList([]const u8).init(interp.allocator);
    defer argv.deinit();
    
    if (std.mem.eql(u8, pm, "apt")) {
        try argv.append("sudo");
        try argv.append("apt");
        try argv.append("update");
    } else if (std.mem.eql(u8, pm, "dnf")) {
        try argv.append("sudo");
        try argv.append("dnf");
        try argv.append("check-update");
    } else if (std.mem.eql(u8, pm, "pacman")) {
        try argv.append("sudo");
        try argv.append("pacman");
        try argv.append("-Sy");
    } else {
        return Value{ .Bool = false };
    }
    
    const output = execCommand(interp.allocator, argv.items) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(output);
    
    return Value{ .Bool = true };
}

/// pkg_upgrade() - 升级所有软件包
pub fn builtin_pkg_upgrade(interp: *Interpreter, _: []Value) InterpreterError!Value {
    const pm = detectPackageManager(interp.allocator) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(pm);
    
    var argv = std.ArrayList([]const u8).init(interp.allocator);
    defer argv.deinit();
    
    if (std.mem.eql(u8, pm, "apt")) {
        try argv.append("sudo");
        try argv.append("apt");
        try argv.append("upgrade");
        try argv.append("-y");
    } else if (std.mem.eql(u8, pm, "dnf")) {
        try argv.append("sudo");
        try argv.append("dnf");
        try argv.append("upgrade");
        try argv.append("-y");
    } else if (std.mem.eql(u8, pm, "pacman")) {
        try argv.append("sudo");
        try argv.append("pacman");
        try argv.append("-Syu");
        try argv.append("--noconfirm");
    } else {
        return Value{ .Bool = false };
    }
    
    const output = execCommand(interp.allocator, argv.items) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(output);
    
    return Value{ .Bool = true };
}

/// pkg_search(keyword) - 搜索软件包
pub fn builtin_pkg_search(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    }
    
    const keyword = args[0].String;
    const pm = detectPackageManager(interp.allocator) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    };
    defer interp.allocator.free(pm);
    
    var argv = std.ArrayList([]const u8).init(interp.allocator);
    defer argv.deinit();
    
    if (std.mem.eql(u8, pm, "apt")) {
        try argv.append("apt");
        try argv.append("search");
        try argv.append(keyword);
    } else if (std.mem.eql(u8, pm, "dnf")) {
        try argv.append("dnf");
        try argv.append("search");
        try argv.append(keyword);
    } else if (std.mem.eql(u8, pm, "pacman")) {
        try argv.append("pacman");
        try argv.append("-Ss");
        try argv.append(keyword);
    } else {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    }
    
    const output = execCommand(interp.allocator, argv.items) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    };
    
    return Value{ .String = output };
}

/// pkg_list_installed() - 列出已安装的软件包
pub fn builtin_pkg_list_installed(interp: *Interpreter, _: []Value) InterpreterError!Value {
    const pm = detectPackageManager(interp.allocator) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    };
    defer interp.allocator.free(pm);
    
    var argv = std.ArrayList([]const u8).init(interp.allocator);
    defer argv.deinit();
    
    if (std.mem.eql(u8, pm, "apt")) {
        try argv.append("dpkg");
        try argv.append("-l");
    } else if (std.mem.eql(u8, pm, "dnf")) {
        try argv.append("dnf");
        try argv.append("list");
        try argv.append("installed");
    } else if (std.mem.eql(u8, pm, "pacman")) {
        try argv.append("pacman");
        try argv.append("-Q");
    } else {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    }
    
    const output = execCommand(interp.allocator, argv.items) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    };
    
    return Value{ .String = output };
}

/// pkg_info(package) - 获取软件包信息
pub fn builtin_pkg_info(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    }
    
    const package = args[0].String;
    const pm = detectPackageManager(interp.allocator) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    };
    defer interp.allocator.free(pm);
    
    var argv = std.ArrayList([]const u8).init(interp.allocator);
    defer argv.deinit();
    
    if (std.mem.eql(u8, pm, "apt")) {
        try argv.append("apt");
        try argv.append("show");
        try argv.append(package);
    } else if (std.mem.eql(u8, pm, "dnf")) {
        try argv.append("dnf");
        try argv.append("info");
        try argv.append(package);
    } else if (std.mem.eql(u8, pm, "pacman")) {
        try argv.append("pacman");
        try argv.append("-Si");
        try argv.append(package);
    } else {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    }
    
    const output = execCommand(interp.allocator, argv.items) catch {
        return Value{ .String = try interp.allocator.dupe(u8, "") };
    };
    
    return Value{ .String = output };
}
