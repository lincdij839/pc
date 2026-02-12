// PC Language PWN Module - pwntools-like functionality
const std = @import("std");
const Value = @import("../interpreter.zig").Value;
const c = @cImport({
    @cInclude("unistd.h");
    @cInclude("sys/types.h");
    @cInclude("sys/wait.h");
});

pub const ProcessHandle = struct {
    pid: c.pid_t,
    stdin_pipe: [2]c_int,
    stdout_pipe: [2]c_int,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, binary: []const u8) !ProcessHandle {
        var stdin_pipe: [2]c_int = undefined;
        var stdout_pipe: [2]c_int = undefined;

        // Create pipes
        if (c.pipe(&stdin_pipe) < 0) return error.PipeCreationFailed;
        if (c.pipe(&stdout_pipe) < 0) {
            _ = c.close(stdin_pipe[0]);
            _ = c.close(stdin_pipe[1]);
            return error.PipeCreationFailed;
        }

        const pid = c.fork();
        if (pid < 0) {
            return error.ForkFailed;
        }

        if (pid == 0) {
            // Child process
            _ = c.dup2(stdin_pipe[0], c.STDIN_FILENO);
            _ = c.dup2(stdout_pipe[1], c.STDOUT_FILENO);

            _ = c.close(stdin_pipe[0]);
            _ = c.close(stdin_pipe[1]);
            _ = c.close(stdout_pipe[0]);
            _ = c.close(stdout_pipe[1]);

            // Execute binary
            const argv = [_:null]?[*:0]const u8{ binary.ptr, null };
            _ = c.execv(binary.ptr, &argv);
            std.os.exit(1);
        }

        // Parent process
        _ = c.close(stdin_pipe[0]);
        _ = c.close(stdout_pipe[1]);

        return ProcessHandle{
            .pid = pid,
            .stdin_pipe = stdin_pipe,
            .stdout_pipe = stdout_pipe,
            .allocator = allocator,
        };
    }

    pub fn send(self: *ProcessHandle, data: []const u8) !void {
        const written = c.write(self.stdin_pipe[1], data.ptr, data.len);
        if (written < 0) return error.WriteFailed;
    }

    pub fn sendline(self: *ProcessHandle, data: []const u8) !void {
        try self.send(data);
        try self.send("\n");
    }

    pub fn recv(self: *ProcessHandle, size: usize) ![]u8 {
        const buffer = try self.allocator.alloc(u8, size);
        const n = c.read(self.stdout_pipe[0], buffer.ptr, size);
        if (n < 0) return error.ReadFailed;
        return buffer[0..@intCast(n)];
    }

    pub fn recvline(self: *ProcessHandle) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        var buf: [1]u8 = undefined;

        while (true) {
            const n = c.read(self.stdout_pipe[0], &buf, 1);
            if (n <= 0) break;
            if (buf[0] == '\n') break;
            try result.append(buf[0]);
        }

        return try result.toOwnedSlice();
    }

    pub fn close(self: *ProcessHandle) void {
        _ = c.close(self.stdin_pipe[1]);
        _ = c.close(self.stdout_pipe[0]);
        _ = c.kill(self.pid, c.SIGTERM);
        _ = c.waitpid(self.pid, null, 0);
    }
};

// Packing/Unpacking utilities
pub fn p8(value: u8) [1]u8 {
    return .{value};
}

pub fn p16(value: u16) [2]u8 {
    var result: [2]u8 = undefined;
    std.mem.writeInt(u16, &result, value, .little);
    return result;
}

pub fn p32(value: u32) [4]u8 {
    var result: [4]u8 = undefined;
    std.mem.writeInt(u32, &result, value, .little);
    return result;
}

pub fn p64(value: u64) [8]u8 {
    var result: [8]u8 = undefined;
    std.mem.writeInt(u64, &result, value, .little);
    return result;
}

pub fn u8(data: []const u8) u8 {
    if (data.len < 1) return 0;
    return data[0];
}

pub fn u16(data: []const u8) u16 {
    if (data.len < 2) return 0;
    return std.mem.readInt(u16, data[0..2], .little);
}

pub fn u32(data: []const u8) u32 {
    if (data.len < 4) return 0;
    return std.mem.readInt(u32, data[0..4], .little);
}

pub fn u64(data: []const u8) u64 {
    if (data.len < 8) return 0;
    return std.mem.readInt(u64, data[0..8], .little);
}

// Cyclic pattern generation
pub fn cyclic(allocator: std.mem.Allocator, length: usize) ![]u8 {
    const alphabet = "abcdefghijklmnopqrstuvwxyz";
    var result = try allocator.alloc(u8, length);

    var i: usize = 0;
    var a: usize = 0;
    var b: usize = 0;
    var c: usize = 0;

    while (i < length) : (i += 1) {
        result[i] = alphabet[a];
        i += 1;
        if (i >= length) break;
        result[i] = alphabet[b];
        i += 1;
        if (i >= length) break;
        result[i] = alphabet[c];

        c += 1;
        if (c >= alphabet.len) {
            c = 0;
            b += 1;
            if (b >= alphabet.len) {
                b = 0;
                a += 1;
            }
        }
    }

    return result;
}

pub fn cyclicFind(pattern: []const u8) ?usize {
    // TODO: Implement pattern finding
    _ = pattern;
    return null;
}

// PWN Module exports for PC language
pub const PwnModule = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) PwnModule {
        return .{ .allocator = allocator };
    }

    pub fn process(self: *PwnModule, binary: []const u8) !ProcessHandle {
        return try ProcessHandle.init(self.allocator, binary);
    }

    pub fn p64Value(self: *PwnModule, value: i64) !Value {
        _ = self;
        const packed = p64(@intCast(value));
        return Value{ .String = &packed };
    }

    pub fn u64Value(self: *PwnModule, data: []const u8) !Value {
        _ = self;
        const unpacked = u64(data);
        return Value{ .Int = @intCast(unpacked) };
    }
};

test "pwn pack/unpack" {
    const value: u64 = 0xdeadbeef;
    const packed = p64(value);
    const unpacked = u64(&packed);
    try std.testing.expectEqual(value, unpacked);
}
