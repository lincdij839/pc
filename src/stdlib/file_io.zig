// PC Language - File I/O Operations
const std = @import("std");
const Value = @import("../interpreter.zig").Value;
const InterpreterError = @import("../interpreter.zig").InterpreterError;

/// 文件句柄
pub const FileHandle = struct {
    file: std.fs.File,
    path: []const u8,
    mode: []const u8,
    allocator: std.mem.Allocator,
    closed: bool,

    pub fn init(allocator: std.mem.Allocator, path: []const u8, mode: []const u8) !FileHandle {
        const file = if (std.mem.eql(u8, mode, "r"))
            try std.fs.cwd().openFile(path, .{})
        else if (std.mem.eql(u8, mode, "w"))
            try std.fs.cwd().createFile(path, .{})
        else if (std.mem.eql(u8, mode, "a"))
            try std.fs.cwd().createFile(path, .{ .truncate = false })
        else
            return error.InvalidMode;

        return FileHandle{
            .file = file,
            .path = path,
            .mode = mode,
            .allocator = allocator,
            .closed = false,
        };
    }

    pub fn close(self: *FileHandle) void {
        if (!self.closed) {
            self.file.close();
            self.closed = true;
        }
    }

    pub fn read(self: *FileHandle) ![]const u8 {
        if (self.closed) return error.FileClosed;
        
        const stat = try self.file.stat();
        const size = stat.size;
        
        const buffer = try self.allocator.alloc(u8, size);
        const bytes_read = try self.file.readAll(buffer);
        
        return buffer[0..bytes_read];
    }

    pub fn readLine(self: *FileHandle) !?[]const u8 {
        if (self.closed) return error.FileClosed;
        
        var buffer = std.ArrayList(u8).init(self.allocator);
        defer buffer.deinit();
        
        const reader = self.file.reader();
        reader.streamUntilDelimiter(buffer.writer(), '\n', null) catch |err| {
            if (err == error.EndOfStream) {
                if (buffer.items.len == 0) return null;
                return try self.allocator.dupe(u8, buffer.items);
            }
            return err;
        };
        
        return try self.allocator.dupe(u8, buffer.items);
    }

    pub fn write(self: *FileHandle, data: []const u8) !void {
        if (self.closed) return error.FileClosed;
        try self.file.writeAll(data);
    }

    pub fn writeLine(self: *FileHandle, data: []const u8) !void {
        if (self.closed) return error.FileClosed;
        try self.file.writeAll(data);
        try self.file.writeAll("\n");
    }
};

/// open(path, mode) - 打开文件
pub fn open(allocator: std.mem.Allocator, args: []const Value) InterpreterError!Value {
    if (args.len < 1 or args.len > 2) {
        std.debug.print("open() requires 1 or 2 arguments\n", .{});
        return InterpreterError.RuntimeError;
    }

    const path = switch (args[0]) {
        .String => |s| s,
        else => {
            std.debug.print("open() path must be a string\n", .{});
            return InterpreterError.TypeError;
        },
    };

    const mode = if (args.len == 2) switch (args[1]) {
        .String => |s| s,
        else => {
            std.debug.print("open() mode must be a string\n", .{});
            return InterpreterError.TypeError;
        },
    } else "r";

    const handle = FileHandle.init(allocator, path, mode) catch |err| {
        std.debug.print("Failed to open file: {}\n", .{err});
        return InterpreterError.RuntimeError;
    };

    // 这里需要返回一个文件对象
    // 暂时返回字符串表示
    _ = handle;
    return Value{ .String = "FileHandle" };
}

/// read_file(path) - 读取整个文件
pub fn readFile(allocator: std.mem.Allocator, args: []const Value) InterpreterError!Value {
    if (args.len != 1) {
        std.debug.print("read_file() requires 1 argument\n", .{});
        return InterpreterError.RuntimeError;
    }

    const path = switch (args[0]) {
        .String => |s| s,
        else => {
            std.debug.print("read_file() path must be a string\n", .{});
            return InterpreterError.TypeError;
        },
    };

    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        std.debug.print("Failed to open file: {}\n", .{err});
        return InterpreterError.RuntimeError;
    };
    defer file.close();

    const stat = file.stat() catch |err| {
        std.debug.print("Failed to stat file: {}\n", .{err});
        return InterpreterError.RuntimeError;
    };

    const content = file.readToEndAlloc(allocator, stat.size) catch |err| {
        std.debug.print("Failed to read file: {}\n", .{err});
        return InterpreterError.RuntimeError;
    };

    return Value{ .String = content };
}

/// write_file(path, content) - 写入整个文件
pub fn writeFile(allocator: std.mem.Allocator, args: []const Value) InterpreterError!Value {
    _ = allocator;
    
    if (args.len != 2) {
        std.debug.print("write_file() requires 2 arguments\n", .{});
        return InterpreterError.RuntimeError;
    }

    const path = switch (args[0]) {
        .String => |s| s,
        else => {
            std.debug.print("write_file() path must be a string\n", .{});
            return InterpreterError.TypeError;
        },
    };

    const content = switch (args[1]) {
        .String => |s| s,
        else => {
            std.debug.print("write_file() content must be a string\n", .{});
            return InterpreterError.TypeError;
        },
    };

    const file = std.fs.cwd().createFile(path, .{}) catch |err| {
        std.debug.print("Failed to create file: {}\n", .{err});
        return InterpreterError.RuntimeError;
    };
    defer file.close();

    file.writeAll(content) catch |err| {
        std.debug.print("Failed to write file: {}\n", .{err});
        return InterpreterError.RuntimeError;
    };

    return Value.None;
}

/// append_file(path, content) - 追加到文件
pub fn appendFile(allocator: std.mem.Allocator, args: []const Value) InterpreterError!Value {
    _ = allocator;
    
    if (args.len != 2) {
        std.debug.print("append_file() requires 2 arguments\n", .{});
        return InterpreterError.RuntimeError;
    }

    const path = switch (args[0]) {
        .String => |s| s,
        else => {
            std.debug.print("append_file() path must be a string\n", .{});
            return InterpreterError.TypeError;
        },
    };

    const content = switch (args[1]) {
        .String => |s| s,
        else => {
            std.debug.print("append_file() content must be a string\n", .{});
            return InterpreterError.TypeError;
        },
    };

    const file = std.fs.cwd().openFile(path, .{ .mode = .write_only }) catch |err| {
        std.debug.print("Failed to open file: {}\n", .{err});
        return InterpreterError.RuntimeError;
    };
    defer file.close();

    try file.seekFromEnd(0);
    
    file.writeAll(content) catch |err| {
        std.debug.print("Failed to append to file: {}\n", .{err});
        return InterpreterError.RuntimeError;
    };

    return Value.None;
}

/// file_exists(path) - 检查文件是否存在
pub fn fileExists(allocator: std.mem.Allocator, args: []const Value) InterpreterError!Value {
    _ = allocator;
    
    if (args.len != 1) {
        std.debug.print("file_exists() requires 1 argument\n", .{});
        return InterpreterError.RuntimeError;
    }

    const path = switch (args[0]) {
        .String => |s| s,
        else => {
            std.debug.print("file_exists() path must be a string\n", .{});
            return InterpreterError.TypeError;
        },
    };

    std.fs.cwd().access(path, .{}) catch {
        return Value{ .Bool = false };
    };

    return Value{ .Bool = true };
}

/// read_lines(path) - 读取文件所有行
pub fn readLines(allocator: std.mem.Allocator, args: []const Value) InterpreterError!Value {
    if (args.len != 1) {
        std.debug.print("read_lines() requires 1 argument\n", .{});
        return InterpreterError.RuntimeError;
    }

    const path = switch (args[0]) {
        .String => |s| s,
        else => {
            std.debug.print("read_lines() path must be a string\n", .{});
            return InterpreterError.TypeError;
        },
    };

    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        std.debug.print("Failed to open file: {}\n", .{err});
        return InterpreterError.RuntimeError;
    };
    defer file.close();

    var lines = std.ArrayList(Value).init(allocator);
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [4096]u8 = undefined;
    while (in_stream.readUntilDelimiterOrEof(&buf, '\n') catch |err| {
        std.debug.print("Failed to read line: {}\n", .{err});
        return InterpreterError.RuntimeError;
    }) |line| {
        const line_copy = try allocator.dupe(u8, line);
        try lines.append(Value{ .String = line_copy });
    }

    return Value{ .List = lines };
}
