// PC Language - Arena Memory Allocator
// 高性能内存分配器，用于减少碎片和提升分配速度

const std = @import("std");

/// Arena 内存分配器
/// 预分配大块内存，快速分配小对象，批量释放
pub const Arena = struct {
    buffer: []u8,
    offset: usize,
    allocator: std.mem.Allocator,
    
    const Self = @This();
    
    /// 初始化 Arena，预分配指定大小的内存
    pub fn init(allocator: std.mem.Allocator, size: usize) !Self {
        const buffer = try allocator.alloc(u8, size);
        return Self{
            .buffer = buffer,
            .offset = 0,
            .allocator = allocator,
        };
    }
    
    /// 释放 Arena 的所有内存
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.buffer);
    }
    
    /// 从 Arena 分配内存
    pub fn alloc(self: *Self, size: usize, alignment: usize) ![]u8 {
        // 对齐偏移量
        const aligned_offset = std.mem.alignForward(usize, self.offset, alignment);
        
        // 检查是否有足够空间
        if (aligned_offset + size > self.buffer.len) {
            return error.OutOfMemory;
        }
        
        const ptr = self.buffer[aligned_offset..aligned_offset + size];
        self.offset = aligned_offset + size;
        return ptr;
    }
    
    /// 分配指定类型的对象
    pub fn allocType(self: *Self, comptime T: type) !*T {
        const bytes = try self.alloc(@sizeOf(T), @alignOf(T));
        return @ptrCast(@alignCast(bytes.ptr));
    }
    
    /// 分配指定类型的数组
    pub fn allocSlice(self: *Self, comptime T: type, n: usize) ![]T {
        const bytes = try self.alloc(@sizeOf(T) * n, @alignOf(T));
        return @as([*]T, @ptrCast(@alignCast(bytes.ptr)))[0..n];
    }
    
    /// 重置 Arena，保留内存但清空所有分配
    pub fn reset(self: *Self) void {
        self.offset = 0;
    }
    
    /// 获取已使用的内存大小
    pub fn usedSize(self: *Self) usize {
        return self.offset;
    }
    
    /// 获取剩余可用内存大小
    pub fn availableSize(self: *Self) usize {
        return self.buffer.len - self.offset;
    }
    
    /// 打印统计信息
    pub fn printStats(self: *Self) void {
        const used = self.usedSize();
        const total = self.buffer.len;
        const percent = @as(f64, @floatFromInt(used)) / @as(f64, @floatFromInt(total)) * 100.0;
        
        std.debug.print("Arena Statistics:\n", .{});
        std.debug.print("  Total:     {} bytes\n", .{total});
        std.debug.print("  Used:      {} bytes\n", .{used});
        std.debug.print("  Available: {} bytes\n", .{self.availableSize()});
        std.debug.print("  Usage:     {d:.2}%\n", .{percent});
    }
};

/// 创建一个 Zig 标准分配器接口的 Arena 包装
pub fn ArenaAllocator(arena: *Arena) std.mem.Allocator {
    return std.mem.Allocator{
        .ptr = arena,
        .vtable = &.{
            .alloc = arenaAlloc,
            .resize = arenaResize,
            .free = arenaFree,
        },
    };
}

fn arenaAlloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
    _ = ret_addr;
    const self: *Arena = @ptrCast(@alignCast(ctx));
    const alignment = @as(usize, 1) << @as(std.math.Log2Int(usize), @intCast(ptr_align));
    const slice = self.alloc(len, alignment) catch return null;
    return slice.ptr;
}

fn arenaResize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
    _ = ctx;
    _ = buf;
    _ = buf_align;
    _ = new_len;
    _ = ret_addr;
    // Arena 不支持 resize，总是返回 false
    return false;
}

fn arenaFree(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
    _ = ctx;
    _ = buf;
    _ = buf_align;
    _ = ret_addr;
    // Arena 不需要单独释放，什么都不做
}

// 测试
test "Arena basic allocation" {
    var arena = try Arena.init(std.testing.allocator, 1024);
    defer arena.deinit();
    
    const ptr1 = try arena.allocType(u64);
    ptr1.* = 42;
    try std.testing.expectEqual(@as(u64, 42), ptr1.*);
    
    const slice = try arena.allocSlice(u8, 10);
    try std.testing.expectEqual(@as(usize, 10), slice.len);
}

test "Arena reset" {
    var arena = try Arena.init(std.testing.allocator, 1024);
    defer arena.deinit();
    
    _ = try arena.alloc(100, 1);
    const used1 = arena.usedSize();
    try std.testing.expect(used1 > 0);
    
    arena.reset();
    const used2 = arena.usedSize();
    try std.testing.expectEqual(@as(usize, 0), used2);
}
