// PC Language - Intermediate Representation (IR)
// 中间表示层，用于优化和代码生成

const std = @import("std");
const ast = @import("ast.zig");

/// IR 指令类型
pub const IRInst = union(enum) {
    // 内存操作
    load: struct { dest: u32, src: u32 },
    store: struct { dest: u32, value: IRValue },
    alloca: struct { dest: u32, size: usize },
    
    // 算术运算
    add: struct { dest: u32, left: IRValue, right: IRValue },
    sub: struct { dest: u32, left: IRValue, right: IRValue },
    mul: struct { dest: u32, left: IRValue, right: IRValue },
    div: struct { dest: u32, left: IRValue, right: IRValue },
    mod: struct { dest: u32, left: IRValue, right: IRValue },
    neg: struct { dest: u32, value: IRValue },
    
    // 比较运算
    eq: struct { dest: u32, left: IRValue, right: IRValue },
    ne: struct { dest: u32, left: IRValue, right: IRValue },
    lt: struct { dest: u32, left: IRValue, right: IRValue },
    le: struct { dest: u32, left: IRValue, right: IRValue },
    gt: struct { dest: u32, left: IRValue, right: IRValue },
    ge: struct { dest: u32, left: IRValue, right: IRValue },
    
    // 逻辑运算
    and_op: struct { dest: u32, left: IRValue, right: IRValue },
    or_op: struct { dest: u32, left: IRValue, right: IRValue },
    not_op: struct { dest: u32, value: IRValue },
    
    // 控制流
    jump: struct { label: u32 },
    branch: struct { cond: IRValue, true_label: u32, false_label: u32 },
    ret: struct { value: ?IRValue },
    
    // 函数调用
    call: struct { dest: ?u32, func: []const u8, args: []IRValue },
    
    // 标签
    label: struct { id: u32 },
    
    // Phi 节点（用于 SSA）
    phi: struct { dest: u32, values: []struct { value: IRValue, block: u32 } },
    
    pub fn format(self: IRInst, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        
        switch (self) {
            .load => |l| try writer.print("  %{} = load %{}", .{l.dest, l.src}),
            .store => |s| try writer.print("  store %{}, {any}", .{s.dest, s.value}),
            .alloca => |a| try writer.print("  %{} = alloca {}", .{a.dest, a.size}),
            .add => |a| try writer.print("  %{} = add {any}, {any}", .{a.dest, a.left, a.right}),
            .sub => |s| try writer.print("  %{} = sub {any}, {any}", .{s.dest, s.left, s.right}),
            .mul => |m| try writer.print("  %{} = mul {any}, {any}", .{m.dest, m.left, m.right}),
            .div => |d| try writer.print("  %{} = div {any}, {any}", .{d.dest, d.left, d.right}),
            .mod => |m| try writer.print("  %{} = mod {any}, {any}", .{m.dest, m.left, m.right}),
            .neg => |n| try writer.print("  %{} = neg {any}", .{n.dest, n.value}),
            .eq => |e| try writer.print("  %{} = eq {any}, {any}", .{e.dest, e.left, e.right}),
            .ne => |n| try writer.print("  %{} = ne {any}, {any}", .{n.dest, n.left, n.right}),
            .lt => |l| try writer.print("  %{} = lt {any}, {any}", .{l.dest, l.left, l.right}),
            .le => |l| try writer.print("  %{} = le {any}, {any}", .{l.dest, l.left, l.right}),
            .gt => |g| try writer.print("  %{} = gt {any}, {any}", .{g.dest, g.left, g.right}),
            .ge => |g| try writer.print("  %{} = ge {any}, {any}", .{g.dest, g.left, g.right}),
            .and_op => |a| try writer.print("  %{} = and {any}, {any}", .{a.dest, a.left, a.right}),
            .or_op => |o| try writer.print("  %{} = or {any}, {any}", .{o.dest, o.left, o.right}),
            .not_op => |n| try writer.print("  %{} = not {any}", .{n.dest, n.value}),
            .jump => |j| try writer.print("  jump label_{}", .{j.label}),
            .branch => |b| try writer.print("  branch {any}, label_{}, label_{}", .{b.cond, b.true_label, b.false_label}),
            .ret => |r| {
                if (r.value) |v| {
                    try writer.print("  ret {any}", .{v});
                } else {
                    try writer.print("  ret", .{});
                }
            },
            .call => |c| {
                if (c.dest) |d| {
                    try writer.print("  %{} = call {s}(", .{d, c.func});
                } else {
                    try writer.print("  call {s}(", .{c.func});
                }
                for (c.args, 0..) |arg, i| {
                    if (i > 0) try writer.print(", ", .{});
                    try writer.print("{any}", .{arg});
                }
                try writer.print(")", .{});
            },
            .label => |l| try writer.print("label_{}:", .{l.id}),
            .phi => |p| {
                try writer.print("  %{} = phi [", .{p.dest});
                for (p.values, 0..) |v, i| {
                    if (i > 0) try writer.print(", ", .{});
                    try writer.print("{any} from block_{}", .{v.value, v.block});
                }
                try writer.print("]", .{});
            },
        }
    }
};

/// IR 值
pub const IRValue = union(enum) {
    register: u32,
    constant: i64,
    float: f64,
    string: []const u8,
    bool_val: bool,
    none,
    
    pub fn format(self: IRValue, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        
        switch (self) {
            .register => |r| try writer.print("%{}", .{r}),
            .constant => |c| try writer.print("{}", .{c}),
            .float => |f| try writer.print("{d}", .{f}),
            .string => |s| try writer.print("\"{s}\"", .{s}),
            .bool_val => |b| try writer.print("{}", .{b}),
            .none => try writer.print("none", .{}),
        }
    }
};

/// IR 基本块
pub const IRBasicBlock = struct {
    id: u32,
    instructions: std.ArrayList(IRInst),
    predecessors: std.ArrayList(u32),
    successors: std.ArrayList(u32),
    
    pub fn init(allocator: std.mem.Allocator, id: u32) IRBasicBlock {
        return .{
            .id = id,
            .instructions = std.ArrayList(IRInst).init(allocator),
            .predecessors = std.ArrayList(u32).init(allocator),
            .successors = std.ArrayList(u32).init(allocator),
        };
    }
    
    pub fn deinit(self: *IRBasicBlock) void {
        self.instructions.deinit();
        self.predecessors.deinit();
        self.successors.deinit();
    }
};

/// IR 函数
pub const IRFunction = struct {
    name: []const u8,
    params: [][]const u8,
    blocks: std.ArrayList(IRBasicBlock),
    next_register: u32,
    next_label: u32,
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator, name: []const u8, params: [][]const u8) IRFunction {
        return .{
            .name = name,
            .params = params,
            .blocks = std.ArrayList(IRBasicBlock).init(allocator),
            .next_register = 0,
            .next_label = 0,
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *IRFunction) void {
        for (self.blocks.items) |*block| {
            block.deinit();
        }
        self.blocks.deinit();
    }
    
    pub fn allocRegister(self: *IRFunction) u32 {
        const reg = self.next_register;
        self.next_register += 1;
        return reg;
    }
    
    pub fn allocLabel(self: *IRFunction) u32 {
        const label = self.next_label;
        self.next_label += 1;
        return label;
    }
    
    pub fn createBlock(self: *IRFunction) !*IRBasicBlock {
        const id = @as(u32, @intCast(self.blocks.items.len));
        try self.blocks.append(IRBasicBlock.init(self.allocator, id));
        return &self.blocks.items[self.blocks.items.len - 1];
    }
    
    pub fn print(self: *IRFunction, writer: anytype) !void {
        try writer.print("function {s}(", .{self.name});
        for (self.params, 0..) |param, i| {
            if (i > 0) try writer.print(", ", .{});
            try writer.print("{s}", .{param});
        }
        try writer.print(") {{\n", .{});
        
        for (self.blocks.items) |block| {
            try writer.print("block_{}:\n", .{block.id});
            for (block.instructions.items) |inst| {
                try writer.print("{any}\n", .{inst});
            }
        }
        
        try writer.print("}}\n", .{});
    }
};

/// IR 模块
pub const IRModule = struct {
    functions: std.ArrayList(IRFunction),
    globals: std.StringHashMap(IRValue),
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) IRModule {
        return .{
            .functions = std.ArrayList(IRFunction).init(allocator),
            .globals = std.StringHashMap(IRValue).init(allocator),
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *IRModule) void {
        for (self.functions.items) |*func| {
            func.deinit();
        }
        self.functions.deinit();
        self.globals.deinit();
    }
    
    pub fn addFunction(self: *IRModule, func: IRFunction) !void {
        try self.functions.append(func);
    }
    
    pub fn print(self: *IRModule, writer: anytype) !void {
        try writer.print("; PC Language IR Module\n\n", .{});
        
        // 打印全局变量
        var it = self.globals.iterator();
        while (it.next()) |entry| {
            try writer.print("@{s} = {any}\n", .{entry.key_ptr.*, entry.value_ptr.*});
        }
        if (self.globals.count() > 0) {
            try writer.print("\n", .{});
        }
        
        // 打印函数
        for (self.functions.items) |*func| {
            try func.print(writer);
            try writer.print("\n", .{});
        }
    }
};
