// PC Language - Remote System Management
// 远程系统管理模块 - 实现多系统互联
const std = @import("std");
const Interpreter = @import("../../interpreter.zig").Interpreter;
const Value = @import("../../interpreter.zig").Value;

// SSH 连接配置
pub const SSHConfig = struct {
    host: []const u8,
    port: u16 = 22,
    user: []const u8,
    password: ?[]const u8 = null,
    key_file: ?[]const u8 = null,
};

// 远程系统信息
pub const RemoteSystem = struct {
    name: []const u8,
    config: SSHConfig,
    connected: bool = false,
};

// ssh_connect(host, user, password_or_key) -> connection_id
// 连接到远程系统
pub fn builtin_ssh_connect(interp: *Interpreter, args: []Value) !Value {
    if (args.len < 2) {
        std.debug.print("ssh_connect() requires at least 2 arguments: host, user\n", .{});
        return Value.None;
    }

    const host = if (args[0] == .String) args[0].String else {
        std.debug.print("ssh_connect(): host must be a string\n", .{});
        return Value.None;
    };

    const user = if (args[1] == .String) args[1].String else {
        std.debug.print("ssh_connect(): user must be a string\n", .{});
        return Value.None;
    };

    // 构建 SSH 命令测试连接
    const test_cmd = try std.fmt.allocPrint(
        interp.allocator,
        "ssh -o BatchMode=yes -o ConnectTimeout=5 {s}@{s} 'echo connected' 2>/dev/null",
        .{ user, host }
    );
    defer interp.allocator.free(test_cmd);

    // 执行测试连接
    const result = std.process.Child.run(.{
        .allocator = interp.allocator,
        .argv = &[_][]const u8{ "sh", "-c", test_cmd },
    }) catch {
        std.debug.print("Failed to connect to {s}@{s}\n", .{ user, host });
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(result.stdout);
    defer interp.allocator.free(result.stderr);

    const success = result.term.Exited == 0;
    
    if (success) {
        // 返回连接字符串作为标识
        const conn_id = try std.fmt.allocPrint(
            interp.arena.allocator(),
            "{s}@{s}",
            .{ user, host }
        );
        return Value{ .String = conn_id };
    }

    return Value{ .Bool = false };
}

// ssh_exec(connection_id, command) -> output
// 在远程系统上执行命令
pub fn builtin_ssh_exec(interp: *Interpreter, args: []Value) !Value {
    if (args.len < 2) {
        std.debug.print("ssh_exec() requires 2 arguments: connection_id, command\n", .{});
        return Value.None;
    }

    const conn_id = if (args[0] == .String) args[0].String else {
        std.debug.print("ssh_exec(): connection_id must be a string\n", .{});
        return Value.None;
    };

    const command = if (args[1] == .String) args[1].String else {
        std.debug.print("ssh_exec(): command must be a string\n", .{});
        return Value.None;
    };

    // 构建 SSH 命令
    const ssh_cmd = try std.fmt.allocPrint(
        interp.allocator,
        "ssh -o BatchMode=yes {s} '{s}'",
        .{ conn_id, command }
    );
    defer interp.allocator.free(ssh_cmd);

    // 执行远程命令
    const result = std.process.Child.run(.{
        .allocator = interp.allocator,
        .argv = &[_][]const u8{ "sh", "-c", ssh_cmd },
    }) catch {
        std.debug.print("Failed to execute command on {s}\n", .{conn_id});
        return Value.None;
    };
    defer interp.allocator.free(result.stderr);

    // 返回输出（使用 arena）
    const output = try interp.arena.allocator().dupe(u8, result.stdout);
    interp.allocator.free(result.stdout);
    
    // 去除末尾换行符
    const trimmed = std.mem.trimRight(u8, output, "\n\r");
    return Value{ .String = trimmed };
}

// ssh_copy(connection_id, local_path, remote_path) -> success
// 复制文件到远程系统
pub fn builtin_ssh_copy(interp: *Interpreter, args: []Value) !Value {
    if (args.len < 3) {
        std.debug.print("ssh_copy() requires 3 arguments: connection_id, local_path, remote_path\n", .{});
        return Value.None;
    }

    const conn_id = if (args[0] == .String) args[0].String else {
        std.debug.print("ssh_copy(): connection_id must be a string\n", .{});
        return Value.None;
    };

    const local_path = if (args[1] == .String) args[1].String else {
        std.debug.print("ssh_copy(): local_path must be a string\n", .{});
        return Value.None;
    };

    const remote_path = if (args[2] == .String) args[2].String else {
        std.debug.print("ssh_copy(): remote_path must be a string\n", .{});
        return Value.None;
    };

    // 构建 SCP 命令
    const scp_cmd = try std.fmt.allocPrint(
        interp.allocator,
        "scp -o BatchMode=yes {s} {s}:{s}",
        .{ local_path, conn_id, remote_path }
    );
    defer interp.allocator.free(scp_cmd);

    // 执行文件复制
    const result = std.process.Child.run(.{
        .allocator = interp.allocator,
        .argv = &[_][]const u8{ "sh", "-c", scp_cmd },
    }) catch {
        std.debug.print("Failed to copy file to {s}\n", .{conn_id});
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(result.stdout);
    defer interp.allocator.free(result.stderr);

    return Value{ .Bool = result.term.Exited == 0 };
}

// ssh_download(connection_id, remote_path, local_path) -> success
// 从远程系统下载文件
pub fn builtin_ssh_download(interp: *Interpreter, args: []Value) !Value {
    if (args.len < 3) {
        std.debug.print("ssh_download() requires 3 arguments: connection_id, remote_path, local_path\n", .{});
        return Value.None;
    }

    const conn_id = if (args[0] == .String) args[0].String else {
        std.debug.print("ssh_download(): connection_id must be a string\n", .{});
        return Value.None;
    };

    const remote_path = if (args[1] == .String) args[1].String else {
        std.debug.print("ssh_download(): remote_path must be a string\n", .{});
        return Value.None;
    };

    const local_path = if (args[2] == .String) args[2].String else {
        std.debug.print("ssh_download(): local_path must be a string\n", .{});
        return Value.None;
    };

    // 构建 SCP 命令
    const scp_cmd = try std.fmt.allocPrint(
        interp.allocator,
        "scp -o BatchMode=yes {s}:{s} {s}",
        .{ conn_id, remote_path, local_path }
    );
    defer interp.allocator.free(scp_cmd);

    // 执行文件下载
    const result = std.process.Child.run(.{
        .allocator = interp.allocator,
        .argv = &[_][]const u8{ "sh", "-c", scp_cmd },
    }) catch {
        std.debug.print("Failed to download file from {s}\n", .{conn_id});
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(result.stdout);
    defer interp.allocator.free(result.stderr);

    return Value{ .Bool = result.term.Exited == 0 };
}

// remote_distro(connection_id) -> distro_name
// 获取远程系统的发行版信息
pub fn builtin_remote_distro(interp: *Interpreter, args: []Value) !Value {
    if (args.len < 1) {
        std.debug.print("remote_distro() requires 1 argument: connection_id\n", .{});
        return Value.None;
    }

    const conn_id = if (args[0] == .String) args[0].String else {
        std.debug.print("remote_distro(): connection_id must be a string\n", .{});
        return Value.None;
    };

    // 在远程系统上检测发行版
    const detect_cmd = "cat /etc/os-release | grep '^ID=' | cut -d= -f2 | tr -d '\"'";
    
    const ssh_cmd = try std.fmt.allocPrint(
        interp.allocator,
        "ssh -o BatchMode=yes {s} '{s}'",
        .{ conn_id, detect_cmd }
    );
    defer interp.allocator.free(ssh_cmd);

    const result = std.process.Child.run(.{
        .allocator = interp.allocator,
        .argv = &[_][]const u8{ "sh", "-c", ssh_cmd },
    }) catch {
        return Value{ .String = try interp.arena.allocator().dupe(u8, "unknown") };
    };
    defer interp.allocator.free(result.stderr);

    const output = try interp.arena.allocator().dupe(u8, result.stdout);
    interp.allocator.free(result.stdout);
    
    const trimmed = std.mem.trimRight(u8, output, "\n\r");
    return Value{ .String = trimmed };
}

// remote_pkg_install(connection_id, package_name) -> success
// 在远程系统上安装软件包
pub fn builtin_remote_pkg_install(interp: *Interpreter, args: []Value) !Value {
    if (args.len < 2) {
        std.debug.print("remote_pkg_install() requires 2 arguments: connection_id, package_name\n", .{});
        return Value.None;
    }

    const conn_id = if (args[0] == .String) args[0].String else {
        std.debug.print("remote_pkg_install(): connection_id must be a string\n", .{});
        return Value.None;
    };

    const package = if (args[1] == .String) args[1].String else {
        std.debug.print("remote_pkg_install(): package_name must be a string\n", .{});
        return Value.None;
    };

    // 先检测远程系统的包管理器
    const detect_pm = "command -v apt >/dev/null && echo apt || command -v dnf >/dev/null && echo dnf || command -v pacman >/dev/null && echo pacman || echo unknown";
    
    const detect_cmd = try std.fmt.allocPrint(
        interp.allocator,
        "ssh -o BatchMode=yes {s} '{s}'",
        .{ conn_id, detect_pm }
    );
    defer interp.allocator.free(detect_cmd);

    const pm_result = std.process.Child.run(.{
        .allocator = interp.allocator,
        .argv = &[_][]const u8{ "sh", "-c", detect_cmd },
    }) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(pm_result.stderr);

    const pm = std.mem.trimRight(u8, pm_result.stdout, "\n\r");
    defer interp.allocator.free(pm_result.stdout);

    // 根据包管理器构建安装命令
    const install_cmd = if (std.mem.eql(u8, pm, "apt"))
        try std.fmt.allocPrint(interp.allocator, "sudo apt install -y {s}", .{package})
    else if (std.mem.eql(u8, pm, "dnf"))
        try std.fmt.allocPrint(interp.allocator, "sudo dnf install -y {s}", .{package})
    else if (std.mem.eql(u8, pm, "pacman"))
        try std.fmt.allocPrint(interp.allocator, "sudo pacman -S --noconfirm {s}", .{package})
    else
        return Value{ .Bool = false };
    defer interp.allocator.free(install_cmd);

    // 执行远程安装
    const ssh_cmd = try std.fmt.allocPrint(
        interp.allocator,
        "ssh -o BatchMode=yes {s} '{s}'",
        .{ conn_id, install_cmd }
    );
    defer interp.allocator.free(ssh_cmd);

    const result = std.process.Child.run(.{
        .allocator = interp.allocator,
        .argv = &[_][]const u8{ "sh", "-c", ssh_cmd },
    }) catch {
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(result.stdout);
    defer interp.allocator.free(result.stderr);

    return Value{ .Bool = result.term.Exited == 0 };
}

// sync_file(connection_id, local_path, remote_path) -> success
// 同步文件到远程系统（使用 rsync）
pub fn builtin_sync_file(interp: *Interpreter, args: []Value) !Value {
    if (args.len < 3) {
        std.debug.print("sync_file() requires 3 arguments: connection_id, local_path, remote_path\n", .{});
        return Value.None;
    }

    const conn_id = if (args[0] == .String) args[0].String else {
        std.debug.print("sync_file(): connection_id must be a string\n", .{});
        return Value.None;
    };

    const local_path = if (args[1] == .String) args[1].String else {
        std.debug.print("sync_file(): local_path must be a string\n", .{});
        return Value.None;
    };

    const remote_path = if (args[2] == .String) args[2].String else {
        std.debug.print("sync_file(): remote_path must be a string\n", .{});
        return Value.None;
    };

    // 构建 rsync 命令
    const rsync_cmd = try std.fmt.allocPrint(
        interp.allocator,
        "rsync -avz -e 'ssh -o BatchMode=yes' {s} {s}:{s}",
        .{ local_path, conn_id, remote_path }
    );
    defer interp.allocator.free(rsync_cmd);

    // 执行同步
    const result = std.process.Child.run(.{
        .allocator = interp.allocator,
        .argv = &[_][]const u8{ "sh", "-c", rsync_cmd },
    }) catch {
        std.debug.print("Failed to sync file to {s}\n", .{conn_id});
        return Value{ .Bool = false };
    };
    defer interp.allocator.free(result.stdout);
    defer interp.allocator.free(result.stderr);

    return Value{ .Bool = result.term.Exited == 0 };
}
