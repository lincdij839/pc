// PC Language LLVM Code Generator
const std = @import("std");
const ast = @import("ast.zig");
const Node = ast.Node;

pub const CodegenError = error{
    InitializationFailed,
    CodegenFailed,
    VerificationFailed,
    OutOfMemory,
    UnsupportedNode,
    CompilationFailed,
};

pub const Codegen = struct {
    allocator: std.mem.Allocator,
    module_name: []const u8,
    ir_buffer: std.ArrayList(u8),
    string_buffer: std.ArrayList(u8),  // 存储字符串常量定义
    var_counter: usize,
    label_counter: usize,
    indent: usize,
    
    pub fn init(allocator: std.mem.Allocator, module_name: []const u8) !Codegen {
        return Codegen{
            .allocator = allocator,
            .module_name = module_name,
            .ir_buffer = std.ArrayList(u8).init(allocator),
            .string_buffer = std.ArrayList(u8).init(allocator),
            .var_counter = 0,
            .label_counter = 0,
            .indent = 0,
        };
    }

    pub fn deinit(self: *Codegen) void {
        self.ir_buffer.deinit();
        self.string_buffer.deinit();
    }
    
    fn nextVar(self: *Codegen) ![]const u8 {
        const var_name = try std.fmt.allocPrint(self.allocator, "%t{d}", .{self.var_counter});
        self.var_counter += 1;
        return var_name;
    }
    
    fn nextLabel(self: *Codegen) ![]const u8 {
        const label = try std.fmt.allocPrint(self.allocator, "L{d}", .{self.label_counter});
        self.label_counter += 1;
        return label;
    }
    
    fn emit(self: *Codegen, comptime fmt: []const u8, args: anytype) !void {
        const line = try std.fmt.allocPrint(self.allocator, fmt, args);
        defer self.allocator.free(line);
        
        // 添加缩进
        var i: usize = 0;
        while (i < self.indent) : (i += 1) {
            try self.ir_buffer.appendSlice("  ");
        }
        
        try self.ir_buffer.appendSlice(line);
        try self.ir_buffer.append('\n');
    }

    pub fn generate(self: *Codegen, program: *Node) !void {
        // 生成程序体（收集字符串）
        self.indent += 1;
        try self.generateNode(program);
        self.indent -= 1;
        
        // 获取字符串定义
        const string_defs = try self.string_buffer.toOwnedSlice();
        defer self.allocator.free(string_defs);
        
        // 创建最终IR
        var final_ir = std.ArrayList(u8).init(self.allocator);
        defer final_ir.deinit();
        
        // 添加头部
        try final_ir.appendSlice("; ModuleID = '");
        try final_ir.appendSlice(self.module_name);
        try final_ir.appendSlice("'\ntarget triple = \"x86_64-pc-linux-gnu\"\n\n");
        
        try final_ir.appendSlice("; External declarations\n");
        try final_ir.appendSlice("declare i32 @printf(i8*, ...)\n");
        try final_ir.appendSlice("declare i32 @puts(i8*)\n\n");
        
        // 添加字符串定义
        try final_ir.appendSlice("; String constants\n");
        try final_ir.appendSlice("@.str = private unnamed_addr constant [4 x i8] c\"%d\\0A\\00\"\n");
        try final_ir.appendSlice(string_defs);
        try final_ir.appendSlice("\n");
        
        // 添加main函数
        try final_ir.appendSlice("; Main function\n");
        try final_ir.appendSlice("define i32 @main() {\n");
        try final_ir.appendSlice("  entry:\n");
        try final_ir.appendSlice(self.ir_buffer.items);
        try final_ir.appendSlice("  ret i32 0\n");
        try final_ir.appendSlice("}\n");
        
        // 替换主缓冲区
        self.ir_buffer.deinit();
        self.ir_buffer = final_ir.clone() catch return CodegenError.OutOfMemory;
    }
    
    fn generateNode(self: *Codegen, node: *Node) CodegenError!void {
        switch (node.*) {
            .Program => |prog| {
                for (prog.statements.items) |stmt| {
                    try self.generateNode(stmt);
                }
            },
            .LiteralInt => |lit| {
                _ = lit;
                // 整数字面量直接使用，不生成代码
            },
            .LiteralString => |lit| {
                _ = lit;
                // 字符串字面量需要时再生成
            },
            .Identifier => |ident| {
                _ = ident;
                // 标识符引用
            },
            .BinaryOp => |bin| {
                _ = bin;
                // 二元运算
            },
            .FunctionCall => |call| {
                // 处理print函数调用
                if (call.callee.* == .Identifier) {
                    const func_name = call.callee.Identifier.name;
                    if (std.mem.eql(u8, func_name, "print")) {
                        if (call.arguments.items.len > 0) {
                            const arg = call.arguments.items[0];
                            try self.generatePrint(arg);
                        }
                    }
                }
            },
            .Assignment => |assign| {
                _ = assign;
                // 赋值语句
            },
            else => {
                std.debug.print("[Codegen] Unsupported node type\n", .{});
                return CodegenError.UnsupportedNode;
            },
        }
    }
    
    fn generatePrint(self: *Codegen, arg: *Node) !void {
        switch (arg.*) {
            .LiteralString => |lit| {
                // 为字符串创建全局常量
                const str_id = self.var_counter;
                self.var_counter += 1;
                
                const str_len = lit.value.len + 1;
                
                // 添加到字符串缓冲区
                const str_def = try std.fmt.allocPrint(
                    self.allocator,
                    "@.str.{d} = private unnamed_addr constant [{d} x i8] c\"{s}\\00\"\n",
                    .{str_id, str_len, lit.value}
                );
                defer self.allocator.free(str_def);
                try self.string_buffer.appendSlice(str_def);
                
                // 调用puts
                try self.emit("call i32 @puts(i8* getelementptr inbounds ([{d} x i8], [{d} x i8]* @.str.{d}, i32 0, i32 0))",
                    .{str_len, str_len, str_id});
            },
            .LiteralInt => |lit| {
                // 打印整数
                try self.emit("call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 {d})",
                    .{lit.value});
            },
            else => {
                std.debug.print("[Codegen] Unsupported print argument\n", .{});
            },
        }
    }

    pub fn emitIR(self: *Codegen, filename: []const u8) !void {
        const file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();
        
        try file.writeAll(self.ir_buffer.items);
        std.debug.print("[✓] LLVM IR written to: {s}\n", .{filename});
    }

    pub fn emitObject(self: *Codegen, filename: []const u8) !void {
        // 使用clang直接编译IR文件到目标文件
        const ir_file = try std.fmt.allocPrint(self.allocator, "{s}.ll", .{filename[0..filename.len-2]});
        defer self.allocator.free(ir_file);
        
        var child = std.process.Child.init(&[_][]const u8{
            "clang", "-c", ir_file, "-o", filename
        }, self.allocator);
        
        const result = child.spawnAndWait() catch |err| {
            std.debug.print("[✗] Failed to spawn clang: {any}\n", .{err});
            std.debug.print("[i] Make sure clang is installed: sudo apt install clang\n", .{});
            return CodegenError.CompilationFailed;
        };
        
        if (result != .Exited or result.Exited != 0) {
            std.debug.print("[✗] Failed to compile IR to object file\n", .{});
            return CodegenError.CompilationFailed;
        }
        
        std.debug.print("[✓] Object file written to: {s}\n", .{filename});
    }

    pub fn link(allocator: std.mem.Allocator, object_file: []const u8, output_file: []const u8) !void {
        // 使用clang链接目标文件
        var child = std.process.Child.init(&[_][]const u8{
            "clang", object_file, "-o", output_file
        }, allocator);
        
        const result = child.spawnAndWait() catch |err| {
            std.debug.print("[✗] Failed to spawn clang: {any}\n", .{err});
            std.debug.print("[i] Make sure clang is installed: sudo apt install clang\n", .{});
            return CodegenError.CompilationFailed;
        };
        
        if (result != .Exited or result.Exited != 0) {
            std.debug.print("[✗] Failed to link executable\n", .{});
            return CodegenError.CompilationFailed;
        }
        
        std.debug.print("[✓] Executable created: {s}\n", .{output_file});
    }
};
