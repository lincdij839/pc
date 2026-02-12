// PC Language - IR Generator
// 将 AST 转换为 IR

const std = @import("std");
const ast = @import("ast.zig");
const ir = @import("ir.zig");

pub const IRGeneratorError = error{
    InvalidASTNode,
    InvalidAssignmentTarget,
    InvalidFunctionCall,
    UndefinedVariable,
    UnsupportedOperator,
    UnsupportedExpression,
    OutOfMemory,
};

pub const IRGenerator = struct {
    module: ir.IRModule,
    current_function: ?*ir.IRFunction,
    current_block: ?*ir.IRBasicBlock,
    variables: std.StringHashMap(u32),
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) IRGenerator {
        return .{
            .module = ir.IRModule.init(allocator),
            .current_function = null,
            .current_block = null,
            .variables = std.StringHashMap(u32).init(allocator),
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *IRGenerator) void {
        self.module.deinit();
        self.variables.deinit();
    }
    
    /// 生成 IR from AST Program node
    pub fn generate(self: *IRGenerator, program: *ast.Node) IRGeneratorError!void {
        if (program.* != .Program) {
            return error.InvalidASTNode;
        }
        
        // 检查是否有显式的 main 函数
        var has_main = false;
        for (program.Program.statements.items) |stmt| {
            if (stmt.* == .FunctionDef and std.mem.eql(u8, stmt.FunctionDef.name, "main")) {
                has_main = true;
                break;
            }
        }
        
        // 如果没有显式的 main 函数，创建一个隐式的 main 函数包装顶层语句
        if (!has_main) {
            // 创建隐式 main 函数
            const main_func = ir.IRFunction.init(self.allocator, "main", &[_][]const u8{});
            try self.module.addFunction(main_func);
            self.current_function = &self.module.functions.items[self.module.functions.items.len - 1];
            self.current_block = try self.current_function.?.createBlock();
            self.variables.clearRetainingCapacity();
            
            // 处理所有顶层语句
            for (program.Program.statements.items) |stmt| {
                if (stmt.* == .FunctionDef) {
                    // 函数定义单独处理
                    continue;
                }
                try self.generateNode(stmt);
            }
            
            // 添加默认 return 0
            try self.current_block.?.instructions.append(.{ 
                .ret = .{ .value = ir.IRValue{ .constant = 0 } } 
            });
        }
        
        // 处理所有函数定义
        for (program.Program.statements.items) |stmt| {
            if (stmt.* == .FunctionDef) {
                try self.generateNode(stmt);
            }
        }
    }
    
    fn generateNode(self: *IRGenerator, node: *ast.Node) IRGeneratorError!void {
        switch (node.*) {
            .FunctionDef => try self.generateFunction(node),
            .ReturnStatement => try self.generateReturn(node),
            .VariableDecl => try self.generateVarDecl(node),
            .Assignment => try self.generateAssignment(node),
            .IfStatement => try self.generateIf(node),
            .WhileLoop => try self.generateWhile(node),
            .ForLoop => try self.generateFor(node),
            .Block => try self.generateBlock(node),
            else => _ = try self.generateExpr(node),
        }
    }
    
    fn generateBlock(self: *IRGenerator, node: *ast.Node) IRGeneratorError!void {
        if (node.* != .Block) return error.InvalidASTNode;
        
        for (node.Block.statements.items) |stmt| {
            try self.generateNode(stmt);
        }
    }
    
    fn generateFunction(self: *IRGenerator, node: *ast.Node) IRGeneratorError!void {
        if (node.* != .FunctionDef) return error.InvalidASTNode;
        const func = node.FunctionDef;
        
        // 提取参数名称
        var param_names = std.ArrayList([]const u8).init(self.allocator);
        defer param_names.deinit();
        
        for (func.params.items) |param| {
            if (param.* == .Identifier) {
                try param_names.append(param.Identifier.name);
            }
        }
        
        // 创建函数
        const ir_func = ir.IRFunction.init(self.allocator, func.name, param_names.items);
        
        // 设置当前函数
        try self.module.addFunction(ir_func);
        self.current_function = &self.module.functions.items[self.module.functions.items.len - 1];
        
        // 创建入口基本块
        self.current_block = try self.current_function.?.createBlock();
        
        // 为参数分配寄存器
        self.variables.clearRetainingCapacity();
        for (param_names.items) |param| {
            const reg = self.current_function.?.allocRegister();
            try self.variables.put(param, reg);
        }
        
        // 生成函数体
        try self.generateNode(func.body);
        
        // 如果没有显式 return，添加默认 return
        const has_return = blk: {
            if (self.current_block.?.instructions.items.len == 0) break :blk false;
            const last_inst = self.current_block.?.instructions.items[self.current_block.?.instructions.items.len - 1];
            break :blk last_inst == .ret;
        };
        
        if (!has_return) {
            try self.current_block.?.instructions.append(.{ .ret = .{ .value = null } });
        }
    }
    
    fn generateReturn(self: *IRGenerator, node: *ast.Node) IRGeneratorError!void {
        if (node.* != .ReturnStatement) return error.InvalidASTNode;
        const ret = node.ReturnStatement;
        
        if (ret.value) |value| {
            const val = try self.generateExpr(value);
            try self.current_block.?.instructions.append(.{ .ret = .{ .value = val } });
        } else {
            try self.current_block.?.instructions.append(.{ .ret = .{ .value = null } });
        }
    }
    
    fn generateVarDecl(self: *IRGenerator, node: *ast.Node) IRGeneratorError!void {
        if (node.* != .VariableDecl) return error.InvalidASTNode;
        const decl = node.VariableDecl;
        
        const reg = self.current_function.?.allocRegister();
        try self.variables.put(decl.name, reg);
        
        if (decl.initializer) |value| {
            const val = try self.generateExpr(value);
            try self.current_block.?.instructions.append(.{ .store = .{ .dest = reg, .value = val } });
        }
    }
    
    fn generateAssignment(self: *IRGenerator, node: *ast.Node) IRGeneratorError!void {
        if (node.* != .Assignment) return error.InvalidASTNode;
        const assign = node.Assignment;
        
        // 获取目标变量名
        const name = if (assign.target.* == .Identifier) 
            assign.target.Identifier.name 
        else 
            return error.InvalidAssignmentTarget;
        
        const val = try self.generateExpr(assign.value);
        const reg = self.variables.get(name) orelse {
            // 如果变量不存在，创建新的
            const new_reg = self.current_function.?.allocRegister();
            try self.variables.put(name, new_reg);
            try self.current_block.?.instructions.append(.{ .store = .{ .dest = new_reg, .value = val } });
            return;
        };
        try self.current_block.?.instructions.append(.{ .store = .{ .dest = reg, .value = val } });
    }
    
    fn generateIf(self: *IRGenerator, node: *ast.Node) IRGeneratorError!void {
        if (node.* != .IfStatement) return error.InvalidASTNode;
        const if_stmt = node.IfStatement;
        
        const cond = try self.generateExpr(if_stmt.condition);
        
        const then_label = self.current_function.?.allocLabel();
        const else_label = self.current_function.?.allocLabel();
        const end_label = self.current_function.?.allocLabel();
        
        // 条件分支
        try self.current_block.?.instructions.append(.{
            .branch = .{
                .cond = cond,
                .true_label = then_label,
                .false_label = if (if_stmt.else_branch != null) else_label else end_label,
            },
        });
        
        // Then 块
        self.current_block = try self.current_function.?.createBlock();
        try self.current_block.?.instructions.append(.{ .label = .{ .id = then_label } });
        try self.generateNode(if_stmt.then_branch);
        try self.current_block.?.instructions.append(.{ .jump = .{ .label = end_label } });
        
        // Else 块
        if (if_stmt.else_branch) |else_branch| {
            self.current_block = try self.current_function.?.createBlock();
            try self.current_block.?.instructions.append(.{ .label = .{ .id = else_label } });
            try self.generateNode(else_branch);
            try self.current_block.?.instructions.append(.{ .jump = .{ .label = end_label } });
        }
        
        // End 块
        self.current_block = try self.current_function.?.createBlock();
        try self.current_block.?.instructions.append(.{ .label = .{ .id = end_label } });
    }
    
    fn generateWhile(self: *IRGenerator, node: *ast.Node) IRGeneratorError!void {
        if (node.* != .WhileLoop) return error.InvalidASTNode;
        const while_stmt = node.WhileLoop;
        
        const cond_label = self.current_function.?.allocLabel();
        const body_label = self.current_function.?.allocLabel();
        const end_label = self.current_function.?.allocLabel();
        
        // 跳转到条件检查
        try self.current_block.?.instructions.append(.{ .jump = .{ .label = cond_label } });
        
        // 条件块
        self.current_block = try self.current_function.?.createBlock();
        try self.current_block.?.instructions.append(.{ .label = .{ .id = cond_label } });
        const cond = try self.generateExpr(while_stmt.condition);
        try self.current_block.?.instructions.append(.{
            .branch = .{ .cond = cond, .true_label = body_label, .false_label = end_label },
        });
        
        // 循环体
        self.current_block = try self.current_function.?.createBlock();
        try self.current_block.?.instructions.append(.{ .label = .{ .id = body_label } });
        try self.generateNode(while_stmt.body);
        try self.current_block.?.instructions.append(.{ .jump = .{ .label = cond_label } });
        
        // End 块
        self.current_block = try self.current_function.?.createBlock();
        try self.current_block.?.instructions.append(.{ .label = .{ .id = end_label } });
    }
    
    fn generateFor(self: *IRGenerator, node: *ast.Node) IRGeneratorError!void {
        if (node.* != .ForLoop) return error.InvalidASTNode;
        const for_stmt = node.ForLoop;
        
        // For now, simplified - just generate the body in a loop
        // TODO: Implement proper iterator protocol
        const body_label = self.current_function.?.allocLabel();
        const end_label = self.current_function.?.allocLabel();
        
        // 简化版本：直接生成循环体
        self.current_block = try self.current_function.?.createBlock();
        try self.current_block.?.instructions.append(.{ .label = .{ .id = body_label } });
        try self.generateNode(for_stmt.body);
        try self.current_block.?.instructions.append(.{ .jump = .{ .label = end_label } });
        
        // End 块
        self.current_block = try self.current_function.?.createBlock();
        try self.current_block.?.instructions.append(.{ .label = .{ .id = end_label } });
    }
    
    fn generateExpr(self: *IRGenerator, node: *ast.Node) IRGeneratorError!ir.IRValue {
        switch (node.*) {
            .LiteralInt => |i| return ir.IRValue{ .constant = i.value },
            .LiteralFloat => |f| return ir.IRValue{ .float = f.value },
            .LiteralString => |s| return ir.IRValue{ .string = s.value },
            .LiteralBool => |b| return ir.IRValue{ .bool_val = b.value },
            
            .Identifier => |ident| {
                const reg = self.variables.get(ident.name) orelse return error.UndefinedVariable;
                const dest = self.current_function.?.allocRegister();
                try self.current_block.?.instructions.append(.{ .load = .{ .dest = dest, .src = reg } });
                return ir.IRValue{ .register = dest };
            },
            
            .BinaryOp => |binop| {
                const left = try self.generateExpr(binop.left);
                const right = try self.generateExpr(binop.right);
                const dest = self.current_function.?.allocRegister();
                
                const inst = if (std.mem.eql(u8, binop.operator, "+"))
                    ir.IRInst{ .add = .{ .dest = dest, .left = left, .right = right } }
                else if (std.mem.eql(u8, binop.operator, "-"))
                    ir.IRInst{ .sub = .{ .dest = dest, .left = left, .right = right } }
                else if (std.mem.eql(u8, binop.operator, "*"))
                    ir.IRInst{ .mul = .{ .dest = dest, .left = left, .right = right } }
                else if (std.mem.eql(u8, binop.operator, "/"))
                    ir.IRInst{ .div = .{ .dest = dest, .left = left, .right = right } }
                else if (std.mem.eql(u8, binop.operator, "%"))
                    ir.IRInst{ .mod = .{ .dest = dest, .left = left, .right = right } }
                else if (std.mem.eql(u8, binop.operator, "=="))
                    ir.IRInst{ .eq = .{ .dest = dest, .left = left, .right = right } }
                else if (std.mem.eql(u8, binop.operator, "!="))
                    ir.IRInst{ .ne = .{ .dest = dest, .left = left, .right = right } }
                else if (std.mem.eql(u8, binop.operator, "<"))
                    ir.IRInst{ .lt = .{ .dest = dest, .left = left, .right = right } }
                else if (std.mem.eql(u8, binop.operator, "<="))
                    ir.IRInst{ .le = .{ .dest = dest, .left = left, .right = right } }
                else if (std.mem.eql(u8, binop.operator, ">"))
                    ir.IRInst{ .gt = .{ .dest = dest, .left = left, .right = right } }
                else if (std.mem.eql(u8, binop.operator, ">="))
                    ir.IRInst{ .ge = .{ .dest = dest, .left = left, .right = right } }
                else if (std.mem.eql(u8, binop.operator, "&&") or std.mem.eql(u8, binop.operator, "and"))
                    ir.IRInst{ .and_op = .{ .dest = dest, .left = left, .right = right } }
                else if (std.mem.eql(u8, binop.operator, "||") or std.mem.eql(u8, binop.operator, "or"))
                    ir.IRInst{ .or_op = .{ .dest = dest, .left = left, .right = right } }
                else
                    return error.UnsupportedOperator;
                
                try self.current_block.?.instructions.append(inst);
                return ir.IRValue{ .register = dest };
            },
            
            .UnaryOp => |unop| {
                const value = try self.generateExpr(unop.operand);
                const dest = self.current_function.?.allocRegister();
                
                const inst = if (std.mem.eql(u8, unop.operator, "-"))
                    ir.IRInst{ .neg = .{ .dest = dest, .value = value } }
                else if (std.mem.eql(u8, unop.operator, "!") or std.mem.eql(u8, unop.operator, "not"))
                    ir.IRInst{ .not_op = .{ .dest = dest, .value = value } }
                else
                    return error.UnsupportedOperator;
                
                try self.current_block.?.instructions.append(inst);
                return ir.IRValue{ .register = dest };
            },
            
            .FunctionCall => |call| {
                var args = std.ArrayList(ir.IRValue).init(self.allocator);
                
                for (call.arguments.items) |arg| {
                    try args.append(try self.generateExpr(arg));
                }
                
                // 获取函数名
                const func_name = if (call.callee.* == .Identifier)
                    call.callee.Identifier.name
                else
                    return error.InvalidFunctionCall;
                
                const dest = self.current_function.?.allocRegister();
                const args_slice = try args.toOwnedSlice();
                try self.current_block.?.instructions.append(.{
                    .call = .{
                        .dest = dest,
                        .func = func_name,
                        .args = args_slice,
                    },
                });
                
                return ir.IRValue{ .register = dest };
            },
            
            .LiteralList => |list| {
                // 为列表分配内存
                const dest = self.current_function.?.allocRegister();
                const size = list.elements.items.len;
                
                // 分配列表空间
                try self.current_block.?.instructions.append(.{
                    .alloca = .{ .dest = dest, .size = size * 8 }, // 假设每个元素 8 字节
                });
                
                // 存储每个元素
                for (list.elements.items, 0..) |elem, i| {
                    const elem_val = try self.generateExpr(elem);
                    const offset_reg = self.current_function.?.allocRegister();
                    
                    // 计算偏移量
                    try self.current_block.?.instructions.append(.{
                        .add = .{
                            .dest = offset_reg,
                            .left = ir.IRValue{ .register = dest },
                            .right = ir.IRValue{ .constant = @intCast(i * 8) },
                        },
                    });
                    
                    // 存储元素
                    try self.current_block.?.instructions.append(.{
                        .store = .{ .dest = offset_reg, .value = elem_val },
                    });
                }
                
                return ir.IRValue{ .register = dest };
            },
            
            .LiteralDict => |dict| {
                // 字典实现为键值对数组
                const dest = self.current_function.?.allocRegister();
                const size = dict.keys.items.len;
                
                // 分配字典空间（键值对，每对 16 字节）
                try self.current_block.?.instructions.append(.{
                    .alloca = .{ .dest = dest, .size = size * 16 },
                });
                
                // 存储每个键值对
                for (dict.keys.items, dict.values.items, 0..) |key, value, i| {
                    const key_val = try self.generateExpr(key);
                    const value_val = try self.generateExpr(value);
                    
                    // 存储键
                    const key_offset_reg = self.current_function.?.allocRegister();
                    try self.current_block.?.instructions.append(.{
                        .add = .{
                            .dest = key_offset_reg,
                            .left = ir.IRValue{ .register = dest },
                            .right = ir.IRValue{ .constant = @intCast(i * 16) },
                        },
                    });
                    try self.current_block.?.instructions.append(.{
                        .store = .{ .dest = key_offset_reg, .value = key_val },
                    });
                    
                    // 存储值
                    const value_offset_reg = self.current_function.?.allocRegister();
                    try self.current_block.?.instructions.append(.{
                        .add = .{
                            .dest = value_offset_reg,
                            .left = ir.IRValue{ .register = dest },
                            .right = ir.IRValue{ .constant = @intCast(i * 16 + 8) },
                        },
                    });
                    try self.current_block.?.instructions.append(.{
                        .store = .{ .dest = value_offset_reg, .value = value_val },
                    });
                }
                
                return ir.IRValue{ .register = dest };
            },
            
            .IndexAccess => |access| {
                // 获取数组/列表的基地址
                const base = try self.generateExpr(access.object);
                const index = try self.generateExpr(access.index);
                
                // 计算偏移量（index * 8）
                const offset_reg = self.current_function.?.allocRegister();
                try self.current_block.?.instructions.append(.{
                    .mul = .{
                        .dest = offset_reg,
                        .left = index,
                        .right = ir.IRValue{ .constant = 8 },
                    },
                });
                
                // 计算实际地址
                const addr_reg = self.current_function.?.allocRegister();
                try self.current_block.?.instructions.append(.{
                    .add = .{
                        .dest = addr_reg,
                        .left = base,
                        .right = ir.IRValue{ .register = offset_reg },
                    },
                });
                
                // 加载值
                const dest = self.current_function.?.allocRegister();
                try self.current_block.?.instructions.append(.{
                    .load = .{ .dest = dest, .src = addr_reg },
                });
                
                return ir.IRValue{ .register = dest };
            },
            
            else => return error.UnsupportedExpression,
        }
    }
};
