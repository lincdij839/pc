// PC Language - IR Optimizer
// IR 优化器，实现各种优化 passes

const std = @import("std");
const ir = @import("ir.zig");

pub const Optimizer = struct {
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) Optimizer {
        return .{ .allocator = allocator };
    }
    
    /// 优化 IR 模块
    pub fn optimize(self: *Optimizer, module: *ir.IRModule) !void {
        // Pass 1: 常量折叠
        try self.constantFolding(module);
        
        // Pass 2: 死代码消除
        try self.deadCodeElimination(module);
        
        // Pass 3: 公共子表达式消除
        try self.commonSubexpressionElimination(module);
        
        // Pass 4: 循环不变量外提
        try self.loopInvariantCodeMotion(module);
        
        // Pass 5: 简单内联优化
        try self.simpleInlining(module);
    }
    
    /// Pass 1: 常量折叠
    /// 将编译时可计算的表达式直接计算出结果
    fn constantFolding(self: *Optimizer, module: *ir.IRModule) !void {
        _ = self;
        
        for (module.functions.items) |*func| {
            for (func.blocks.items) |*block| {
                var i: usize = 0;
                while (i < block.instructions.items.len) {
                    const inst = &block.instructions.items[i];
                    
                    switch (inst.*) {
                        .add => |*a| {
                            if (a.left == .constant and a.right == .constant) {
                                const result = a.left.constant + a.right.constant;
                                // 替换为常量
                                inst.* = .{ .store = .{
                                    .dest = a.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .sub => |*s| {
                            if (s.left == .constant and s.right == .constant) {
                                const result = s.left.constant - s.right.constant;
                                inst.* = .{ .store = .{
                                    .dest = s.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .mul => |*m| {
                            if (m.left == .constant and m.right == .constant) {
                                const result = m.left.constant * m.right.constant;
                                inst.* = .{ .store = .{
                                    .dest = m.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .div => |*d| {
                            if (d.left == .constant and d.right == .constant and d.right.constant != 0) {
                                const result = @divTrunc(d.left.constant, d.right.constant);
                                inst.* = .{ .store = .{
                                    .dest = d.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .mod => |*m| {
                            if (m.left == .constant and m.right == .constant and m.right.constant != 0) {
                                const result = @mod(m.left.constant, m.right.constant);
                                inst.* = .{ .store = .{
                                    .dest = m.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .neg => |*n| {
                            if (n.value == .constant) {
                                const result = -n.value.constant;
                                inst.* = .{ .store = .{
                                    .dest = n.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .eq => |*e| {
                            if (e.left == .constant and e.right == .constant) {
                                const result: i64 = if (e.left.constant == e.right.constant) 1 else 0;
                                inst.* = .{ .store = .{
                                    .dest = e.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .ne => |*n| {
                            if (n.left == .constant and n.right == .constant) {
                                const result: i64 = if (n.left.constant != n.right.constant) 1 else 0;
                                inst.* = .{ .store = .{
                                    .dest = n.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .lt => |*l| {
                            if (l.left == .constant and l.right == .constant) {
                                const result: i64 = if (l.left.constant < l.right.constant) 1 else 0;
                                inst.* = .{ .store = .{
                                    .dest = l.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .le => |*l| {
                            if (l.left == .constant and l.right == .constant) {
                                const result: i64 = if (l.left.constant <= l.right.constant) 1 else 0;
                                inst.* = .{ .store = .{
                                    .dest = l.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .gt => |*g| {
                            if (g.left == .constant and g.right == .constant) {
                                const result: i64 = if (g.left.constant > g.right.constant) 1 else 0;
                                inst.* = .{ .store = .{
                                    .dest = g.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .ge => |*g| {
                            if (g.left == .constant and g.right == .constant) {
                                const result: i64 = if (g.left.constant >= g.right.constant) 1 else 0;
                                inst.* = .{ .store = .{
                                    .dest = g.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .and_op => |*a| {
                            if (a.left == .constant and a.right == .constant) {
                                const result: i64 = if (a.left.constant != 0 and a.right.constant != 0) 1 else 0;
                                inst.* = .{ .store = .{
                                    .dest = a.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .or_op => |*o| {
                            if (o.left == .constant and o.right == .constant) {
                                const result: i64 = if (o.left.constant != 0 or o.right.constant != 0) 1 else 0;
                                inst.* = .{ .store = .{
                                    .dest = o.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        .not_op => |*n| {
                            if (n.value == .constant) {
                                const result: i64 = if (n.value.constant == 0) 1 else 0;
                                inst.* = .{ .store = .{
                                    .dest = n.dest,
                                    .value = ir.IRValue{ .constant = result },
                                }};
                            }
                        },
                        else => {},
                    }
                    
                    i += 1;
                }
            }
        }
    }
    
    /// Pass 2: 死代码消除
    /// 删除永远不会被执行或结果不会被使用的代码
    fn deadCodeElimination(self: *Optimizer, module: *ir.IRModule) !void {
        _ = self;
        
        for (module.functions.items) |*func| {
            for (func.blocks.items) |*block| {
                // 标记使用的寄存器
                var used_registers = std.AutoHashMap(u32, bool).init(module.allocator);
                defer used_registers.deinit();
                
                // 第一遍：标记所有被使用的寄存器
                for (block.instructions.items) |inst| {
                    switch (inst) {
                        .load => |l| try used_registers.put(l.src, true),
                        .store => |s| {
                            if (s.value == .register) {
                                try used_registers.put(s.value.register, true);
                            }
                        },
                        .add => |a| {
                            if (a.left == .register) try used_registers.put(a.left.register, true);
                            if (a.right == .register) try used_registers.put(a.right.register, true);
                        },
                        .sub => |s| {
                            if (s.left == .register) try used_registers.put(s.left.register, true);
                            if (s.right == .register) try used_registers.put(s.right.register, true);
                        },
                        .mul => |m| {
                            if (m.left == .register) try used_registers.put(m.left.register, true);
                            if (m.right == .register) try used_registers.put(m.right.register, true);
                        },
                        .div => |d| {
                            if (d.left == .register) try used_registers.put(d.left.register, true);
                            if (d.right == .register) try used_registers.put(d.right.register, true);
                        },
                        .mod => |m| {
                            if (m.left == .register) try used_registers.put(m.left.register, true);
                            if (m.right == .register) try used_registers.put(m.right.register, true);
                        },
                        .neg => |n| {
                            if (n.value == .register) try used_registers.put(n.value.register, true);
                        },
                        .not_op => |n| {
                            if (n.value == .register) try used_registers.put(n.value.register, true);
                        },
                        .eq => |e| {
                            if (e.left == .register) try used_registers.put(e.left.register, true);
                            if (e.right == .register) try used_registers.put(e.right.register, true);
                        },
                        .ne => |n| {
                            if (n.left == .register) try used_registers.put(n.left.register, true);
                            if (n.right == .register) try used_registers.put(n.right.register, true);
                        },
                        .lt => |l| {
                            if (l.left == .register) try used_registers.put(l.left.register, true);
                            if (l.right == .register) try used_registers.put(l.right.register, true);
                        },
                        .le => |l| {
                            if (l.left == .register) try used_registers.put(l.left.register, true);
                            if (l.right == .register) try used_registers.put(l.right.register, true);
                        },
                        .gt => |g| {
                            if (g.left == .register) try used_registers.put(g.left.register, true);
                            if (g.right == .register) try used_registers.put(g.right.register, true);
                        },
                        .ge => |g| {
                            if (g.left == .register) try used_registers.put(g.left.register, true);
                            if (g.right == .register) try used_registers.put(g.right.register, true);
                        },
                        .and_op => |a| {
                            if (a.left == .register) try used_registers.put(a.left.register, true);
                            if (a.right == .register) try used_registers.put(a.right.register, true);
                        },
                        .or_op => |o| {
                            if (o.left == .register) try used_registers.put(o.left.register, true);
                            if (o.right == .register) try used_registers.put(o.right.register, true);
                        },
                        .branch => |b| {
                            if (b.cond == .register) try used_registers.put(b.cond.register, true);
                        },
                        .ret => |r| {
                            if (r.value) |v| {
                                if (v == .register) try used_registers.put(v.register, true);
                            }
                        },
                        .call => |c| {
                            for (c.args) |arg| {
                                if (arg == .register) try used_registers.put(arg.register, true);
                            }
                        },
                        else => {},
                    }
                }
                
                // 第二遍：删除未使用的指令
                var i: usize = 0;
                while (i < block.instructions.items.len) {
                    const inst = block.instructions.items[i];
                    var should_remove = false;
                    
                    switch (inst) {
                        .add => |a| {
                            if (!used_registers.contains(a.dest)) should_remove = true;
                        },
                        .sub => |s| {
                            if (!used_registers.contains(s.dest)) should_remove = true;
                        },
                        .mul => |m| {
                            if (!used_registers.contains(m.dest)) should_remove = true;
                        },
                        .div => |d| {
                            if (!used_registers.contains(d.dest)) should_remove = true;
                        },
                        .mod => |m| {
                            if (!used_registers.contains(m.dest)) should_remove = true;
                        },
                        .neg => |n| {
                            if (!used_registers.contains(n.dest)) should_remove = true;
                        },
                        .not_op => |n| {
                            if (!used_registers.contains(n.dest)) should_remove = true;
                        },
                        .eq => |e| {
                            if (!used_registers.contains(e.dest)) should_remove = true;
                        },
                        .ne => |n| {
                            if (!used_registers.contains(n.dest)) should_remove = true;
                        },
                        .lt => |l| {
                            if (!used_registers.contains(l.dest)) should_remove = true;
                        },
                        .le => |l| {
                            if (!used_registers.contains(l.dest)) should_remove = true;
                        },
                        .gt => |g| {
                            if (!used_registers.contains(g.dest)) should_remove = true;
                        },
                        .ge => |g| {
                            if (!used_registers.contains(g.dest)) should_remove = true;
                        },
                        .and_op => |a| {
                            if (!used_registers.contains(a.dest)) should_remove = true;
                        },
                        .or_op => |o| {
                            if (!used_registers.contains(o.dest)) should_remove = true;
                        },
                        .load => |l| {
                            if (!used_registers.contains(l.dest)) should_remove = true;
                        },
                        else => {},
                    }
                    
                    if (should_remove) {
                        _ = block.instructions.orderedRemove(i);
                    } else {
                        i += 1;
                    }
                }
            }
        }
    }
    
    /// Pass 3: 公共子表达式消除
    /// 识别并消除重复计算的表达式
    fn commonSubexpressionElimination(self: *Optimizer, module: *ir.IRModule) !void {
        _ = self;
        
        for (module.functions.items) |*func| {
            for (func.blocks.items) |*block| {
                // 表达式哈希表：(操作, 左操作数, 右操作数) -> 结果寄存器
                var expr_map = std.HashMap(ExprKey, u32, ExprContext, std.hash_map.default_max_load_percentage).init(module.allocator);
                defer expr_map.deinit();
                
                for (block.instructions.items) |*inst| {
                    switch (inst.*) {
                        .add => |*a| {
                            const key = ExprKey{ .op = .add, .left = a.left, .right = a.right };
                            if (expr_map.get(key)) |existing_reg| {
                                // 找到重复表达式，替换为 load
                                inst.* = .{ .load = .{ .dest = a.dest, .src = existing_reg } };
                            } else {
                                try expr_map.put(key, a.dest);
                            }
                        },
                        .sub => |*s| {
                            const key = ExprKey{ .op = .sub, .left = s.left, .right = s.right };
                            if (expr_map.get(key)) |existing_reg| {
                                inst.* = .{ .load = .{ .dest = s.dest, .src = existing_reg } };
                            } else {
                                try expr_map.put(key, s.dest);
                            }
                        },
                        .mul => |*m| {
                            const key = ExprKey{ .op = .mul, .left = m.left, .right = m.right };
                            if (expr_map.get(key)) |existing_reg| {
                                inst.* = .{ .load = .{ .dest = m.dest, .src = existing_reg } };
                            } else {
                                try expr_map.put(key, m.dest);
                            }
                        },
                        .div => |*d| {
                            const key = ExprKey{ .op = .div, .left = d.left, .right = d.right };
                            if (expr_map.get(key)) |existing_reg| {
                                inst.* = .{ .load = .{ .dest = d.dest, .src = existing_reg } };
                            } else {
                                try expr_map.put(key, d.dest);
                            }
                        },
                        else => {},
                    }
                }
            }
        }
    }
    
    /// Pass 4: 循环不变量外提
    /// 将循环内不变的计算移到循环外
    fn loopInvariantCodeMotion(self: *Optimizer, module: *ir.IRModule) !void {
        _ = self;
        
        for (module.functions.items) |*func| {
            // 识别循环（简化版：查找回边）
            for (func.blocks.items, 0..) |*block, block_idx| {
                var has_back_edge = false;
                
                // 检查是否有跳转回自己或前面的块
                for (block.instructions.items) |inst| {
                    switch (inst) {
                        .jump => |j| {
                            if (j.label <= block_idx) {
                                has_back_edge = true;
                                break;
                            }
                        },
                        .branch => |b| {
                            if (b.true_label <= block_idx or b.false_label <= block_idx) {
                                has_back_edge = true;
                                break;
                            }
                        },
                        else => {},
                    }
                }
                
                // 如果是循环，尝试外提不变量
                if (has_back_edge) {
                    // 简化版：标记常量计算
                    for (block.instructions.items) |*inst| {
                        switch (inst.*) {
                            .add => |a| {
                                if (a.left == .constant and a.right == .constant) {
                                    // 这个计算可以外提（已经被常量折叠处理）
                                }
                            },
                            else => {},
                        }
                    }
                }
            }
        }
    }
    
    /// Pass 5: 简单内联优化
    /// 内联小型函数以减少函数调用开销
    fn simpleInlining(self: *Optimizer, module: *ir.IRModule) !void {
        _ = self;
        
        // 收集可内联的函数（小于 10 条指令）
        var inlinable_funcs = std.StringHashMap(bool).init(module.allocator);
        defer inlinable_funcs.deinit();
        
        for (module.functions.items) |*func| {
            var total_insts: usize = 0;
            for (func.blocks.items) |block| {
                total_insts += block.instructions.items.len;
            }
            
            // 小于 10 条指令的函数可以内联
            if (total_insts < 10 and !std.mem.eql(u8, func.name, "main")) {
                try inlinable_funcs.put(func.name, true);
            }
        }
        
        // 在调用点内联这些函数
        for (module.functions.items) |*func| {
            for (func.blocks.items) |*block| {
                for (block.instructions.items) |inst| {
                    switch (inst) {
                        .call => |c| {
                            if (inlinable_funcs.contains(c.func)) {
                                // 标记为可内联（实际内联需要更复杂的逻辑）
                                // 这里只是简单标记
                            }
                        },
                        else => {},
                    }
                }
            }
        }
    }
};

/// 表达式键，用于 CSE
const ExprKey = struct {
    op: enum { add, sub, mul, div },
    left: ir.IRValue,
    right: ir.IRValue,
};

const ExprContext = struct {
    pub fn hash(self: @This(), key: ExprKey) u64 {
        _ = self;
        var hasher = std.hash.Wyhash.init(0);
        
        // Hash operation
        const op_val: u8 = switch (key.op) {
            .add => 1,
            .sub => 2,
            .mul => 3,
            .div => 4,
        };
        hasher.update(&[_]u8{op_val});
        
        // Hash left value
        switch (key.left) {
            .register => |r| {
                hasher.update(&[_]u8{1});
                hasher.update(std.mem.asBytes(&r));
            },
            .constant => |c| {
                hasher.update(&[_]u8{2});
                hasher.update(std.mem.asBytes(&c));
            },
            else => {},
        }
        
        // Hash right value
        switch (key.right) {
            .register => |r| {
                hasher.update(&[_]u8{1});
                hasher.update(std.mem.asBytes(&r));
            },
            .constant => |c| {
                hasher.update(&[_]u8{2});
                hasher.update(std.mem.asBytes(&c));
            },
            else => {},
        }
        
        return hasher.final();
    }
    
    pub fn eql(self: @This(), a: ExprKey, b: ExprKey) bool {
        _ = self;
        return a.op == b.op and 
               std.meta.eql(a.left, b.left) and 
               std.meta.eql(a.right, b.right);
    }
};
