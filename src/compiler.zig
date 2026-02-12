// PC Language - Compiler Entry Point
// 编译器入口，协调各个编译阶段

const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const ast = @import("ast.zig");
const ir = @import("ir.zig");
const IRGenerator = @import("ir_gen.zig").IRGenerator;
const Optimizer = @import("optimizer.zig").Optimizer;
const Arena = @import("arena.zig").Arena;
const builtin = @import("builtin");

/// 目标平台信息
const TargetInfo = struct {
    name: []const u8,
    triple: []const u8,
    data_layout: []const u8,
    pointer_size: usize,
};

/// 获取当前目标平台信息
fn getTargetInfo() TargetInfo {
    const arch = builtin.target.cpu.arch;
    const os = builtin.target.os.tag;
    
    return switch (arch) {
        .x86_64 => switch (os) {
            .linux => TargetInfo{
                .name = "x86_64 Linux",
                .triple = "x86_64-pc-linux-gnu",
                .data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128",
                .pointer_size = 8,
            },
            .windows => TargetInfo{
                .name = "x86_64 Windows",
                .triple = "x86_64-pc-windows-msvc",
                .data_layout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128",
                .pointer_size = 8,
            },
            .macos => TargetInfo{
                .name = "x86_64 macOS",
                .triple = "x86_64-apple-darwin",
                .data_layout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128",
                .pointer_size = 8,
            },
            else => TargetInfo{
                .name = "x86_64 Unknown",
                .triple = "x86_64-unknown-unknown",
                .data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128",
                .pointer_size = 8,
            },
        },
        .aarch64 => switch (os) {
            .linux => TargetInfo{
                .name = "ARM64 Linux",
                .triple = "aarch64-unknown-linux-gnu",
                .data_layout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128",
                .pointer_size = 8,
            },
            .macos => TargetInfo{
                .name = "ARM64 macOS (Apple Silicon)",
                .triple = "aarch64-apple-darwin",
                .data_layout = "e-m:o-i64:64-i128:128-n32:64-S128",
                .pointer_size = 8,
            },
            else => TargetInfo{
                .name = "ARM64 Unknown",
                .triple = "aarch64-unknown-unknown",
                .data_layout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128",
                .pointer_size = 8,
            },
        },
        .riscv64 => TargetInfo{
            .name = "RISC-V 64-bit",
            .triple = "riscv64-unknown-linux-gnu",
            .data_layout = "e-m:e-p:64:64-i64:64-i128:128-n64-S128",
            .pointer_size = 8,
        },
        .wasm32 => TargetInfo{
            .name = "WebAssembly 32-bit",
            .triple = "wasm32-unknown-unknown",
            .data_layout = "e-m:e-p:32:32-i64:64-n32:64-S128",
            .pointer_size = 4,
        },
        else => TargetInfo{
            .name = "Unknown Platform",
            .triple = "unknown-unknown-unknown",
            .data_layout = "e-m:e-p:64:64-i64:64-n32:64-S128",
            .pointer_size = 8,
        },
    };
}

/// 根据目标字符串获取平台信息（用于交叉编译）
fn getTargetInfoByName(target_name: []const u8) ?TargetInfo {
    if (std.mem.eql(u8, target_name, "x86_64-linux")) {
        return TargetInfo{
            .name = "x86_64 Linux",
            .triple = "x86_64-pc-linux-gnu",
            .data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128",
            .pointer_size = 8,
        };
    } else if (std.mem.eql(u8, target_name, "aarch64-linux") or std.mem.eql(u8, target_name, "arm64-linux")) {
        return TargetInfo{
            .name = "ARM64 Linux",
            .triple = "aarch64-unknown-linux-gnu",
            .data_layout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128",
            .pointer_size = 8,
        };
    } else if (std.mem.eql(u8, target_name, "x86_64-windows")) {
        return TargetInfo{
            .name = "x86_64 Windows",
            .triple = "x86_64-pc-windows-msvc",
            .data_layout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128",
            .pointer_size = 8,
        };
    } else if (std.mem.eql(u8, target_name, "x86_64-macos")) {
        return TargetInfo{
            .name = "x86_64 macOS",
            .triple = "x86_64-apple-darwin",
            .data_layout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128",
            .pointer_size = 8,
        };
    } else if (std.mem.eql(u8, target_name, "aarch64-macos") or std.mem.eql(u8, target_name, "arm64-macos")) {
        return TargetInfo{
            .name = "ARM64 macOS (Apple Silicon)",
            .triple = "aarch64-apple-darwin",
            .data_layout = "e-m:o-i64:64-i128:128-n32:64-S128",
            .pointer_size = 8,
        };
    } else if (std.mem.eql(u8, target_name, "riscv64-linux")) {
        return TargetInfo{
            .name = "RISC-V 64-bit",
            .triple = "riscv64-unknown-linux-gnu",
            .data_layout = "e-m:e-p:64:64-i64:64-i128:128-n64-S128",
            .pointer_size = 8,
        };
    } else if (std.mem.eql(u8, target_name, "wasm32")) {
        return TargetInfo{
            .name = "WebAssembly 32-bit",
            .triple = "wasm32-unknown-unknown",
            .data_layout = "e-m:e-p:32:32-i64:64-n32:64-S128",
            .pointer_size = 4,
        };
    }
    
    return null;
}

pub const CompilerOptions = struct {
    emit_ir: bool = false,
    emit_asm: bool = false,
    optimize: bool = true,
    output_file: ?[]const u8 = null,
    target: ?[]const u8 = null, // 目标平台（用于交叉编译）
};

pub const Compiler = struct {
    allocator: std.mem.Allocator,
    arena: Arena,
    options: CompilerOptions,
    
    pub fn init(allocator: std.mem.Allocator, options: CompilerOptions) !Compiler {
        // 预分配 10MB 的 Arena
        const arena = try Arena.init(allocator, 10 * 1024 * 1024);
        
        return Compiler{
            .allocator = allocator,
            .arena = arena,
            .options = options,
        };
    }
    
    pub fn deinit(self: *Compiler) void {
        self.arena.deinit();
    }
    
    /// 编译源代码文件
    pub fn compileFile(self: *Compiler, source_path: []const u8) !void {
        // 读取源文件
        const source = try std.fs.cwd().readFileAlloc(self.allocator, source_path, 10 * 1024 * 1024);
        defer self.allocator.free(source);
        
        try self.compileSource(source, source_path);
    }
    
    /// 编译源代码字符串
    pub fn compileSource(self: *Compiler, source: []const u8, filename: []const u8) !void {
        const target = getTargetInfo();
        
        std.debug.print("🔨 Compiling {s}...\n", .{filename});
        std.debug.print("   Target: {s}\n", .{target.name});
        std.debug.print("   Triple: {s}\n", .{target.triple});
        std.debug.print("\n", .{});
        
        // 阶段 1: 词法分析
        std.debug.print("  [1/5] Lexical analysis...\n", .{});
        var lexer = Lexer.init(self.allocator, source);
        defer lexer.deinit();
        const tokens = try lexer.scanAll();
        defer tokens.deinit();
        
        std.debug.print("        Tokens: {}\n", .{tokens.items.len});
        
        // 阶段 2: 语法分析
        std.debug.print("  [2/5] Parsing...\n", .{});
        var parser = Parser.init(self.allocator, tokens.items);
        const program = try parser.parseProgram();
        defer ast.freeNode(self.allocator, program);
        
        std.debug.print("        AST nodes created\n", .{});
        
        // 阶段 3: IR 生成
        std.debug.print("  [3/5] Generating IR...\n", .{});
        var ir_module = try self.generateIR(program);
        defer ir_module.deinit();
        
        if (self.options.emit_ir) {
            try self.emitIR(&ir_module, filename);
        }
        
        // 阶段 4: 优化
        if (self.options.optimize) {
            std.debug.print("  [4/5] Optimizing...\n", .{});
            try self.optimize(&ir_module);
        } else {
            std.debug.print("  [4/5] Optimization skipped\n", .{});
        }
        
        // 阶段 5: 代码生成
        std.debug.print("  [5/5] Code generation...\n", .{});
        try self.generateCode(&ir_module, filename);
        
        std.debug.print("✅ Compilation successful!\n", .{});
        
        // 打印 Arena 统计
        self.arena.printStats();
    }
    
    fn generateIR(self: *Compiler, program: *ast.Node) !ir.IRModule {
        // 使用 IRGenerator 来生成 IR
        var ir_gen = IRGenerator.init(self.allocator);
        
        // 生成 IR
        try ir_gen.generate(program);
        
        // 返回生成的模块（转移所有权）
        const module = ir_gen.module;
        
        // 防止 deinit 时释放 module
        ir_gen.module = ir.IRModule.init(self.allocator);
        ir_gen.deinit();
        
        return module;
    }
    
    fn emitIR(self: *Compiler, module: *ir.IRModule, source_filename: []const u8) !void {
        const ir_filename = try std.fmt.allocPrint(
            self.allocator,
            "{s}.ir",
            .{source_filename}
        );
        defer self.allocator.free(ir_filename);
        
        const file = try std.fs.cwd().createFile(ir_filename, .{});
        defer file.close();
        
        const writer = file.writer();
        try module.print(writer);
        
        std.debug.print("        IR written to {s}\n", .{ir_filename});
    }
    
    fn optimize(self: *Compiler, module: *ir.IRModule) !void {
        var optimizer = Optimizer.init(self.allocator);
        try optimizer.optimize(module);
        
        std.debug.print("        Constant folding\n", .{});
        std.debug.print("        Dead code elimination\n", .{});
        std.debug.print("        Common subexpression elimination\n", .{});
        std.debug.print("        Loop invariant code motion\n", .{});
        std.debug.print("        Simple inlining\n", .{});
    }
    
    fn generateCode(self: *Compiler, module: *ir.IRModule, source_filename: []const u8) !void {
        // 生成 LLVM IR 作为中间步骤
        const llvm_ir = try self.generateLLVMIR(module);
        defer self.allocator.free(llvm_ir);
        
        // 写入 .ll 文件
        const ll_filename = try std.fmt.allocPrint(
            self.allocator,
            "{s}.ll",
            .{source_filename}
        );
        defer self.allocator.free(ll_filename);
        
        {
            const file = try std.fs.cwd().createFile(ll_filename, .{});
            defer file.close();
            try file.writeAll(llvm_ir);
        }
        
        std.debug.print("        LLVM IR written to {s}\n", .{ll_filename});
        
        // 使用 LLVM 工具链编译
        const output_file = self.options.output_file orelse "a.out";
        
        // llc: LLVM IR -> 汇编
        const asm_filename = try std.fmt.allocPrint(
            self.allocator,
            "{s}.s",
            .{source_filename}
        );
        defer self.allocator.free(asm_filename);
        
        const llc_cmd = try std.fmt.allocPrint(
            self.allocator,
            "llc {s} -o {s}",
            .{ll_filename, asm_filename}
        );
        defer self.allocator.free(llc_cmd);
        
        _ = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ "sh", "-c", llc_cmd },
        });
        
        // gcc: 汇编 -> 可执行文件
        const gcc_cmd = try std.fmt.allocPrint(
            self.allocator,
            "gcc {s} -o {s}",
            .{asm_filename, output_file}
        );
        defer self.allocator.free(gcc_cmd);
        
        _ = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ "sh", "-c", gcc_cmd },
        });
        
        std.debug.print("        Binary written to {s}\n", .{output_file});
    }
    
    fn generateLLVMIR(self: *Compiler, module: *ir.IRModule) ![]u8 {
        var buffer = std.ArrayList(u8).init(self.allocator);
        const writer = buffer.writer();
        
        // 获取目标平台信息（支持交叉编译）
        const target_info = if (self.options.target) |target_name|
            getTargetInfoByName(target_name) orelse getTargetInfo()
        else
            getTargetInfo();
        
        // LLVM IR 头部
        try writer.writeAll("; ModuleID = 'pc_module'\n");
        try writer.print("; Target: {s}\n", .{target_info.name});
        try writer.print("target datalayout = \"{s}\"\n", .{target_info.data_layout});
        try writer.print("target triple = \"{s}\"\n\n", .{target_info.triple});
        
        // 生成函数
        for (module.functions.items) |*func| {
            try writer.print("define i64 @{s}(", .{func.name});
            
            // 参数
            for (func.params, 0..) |param, i| {
                if (i > 0) try writer.writeAll(", ");
                try writer.print("i64 %{s}", .{param});
            }
            
            try writer.writeAll(") {\n");
            
            // 基本块
            for (func.blocks.items) |block| {
                try writer.print("block_{}:\n", .{block.id});
                
                for (block.instructions.items) |inst| {
                    try self.emitLLVMInst(writer, inst);
                }
            }
            
            try writer.writeAll("}\n\n");
        }
        
        return buffer.toOwnedSlice();
    }
    
    fn emitLLVMInst(self: *Compiler, writer: anytype, inst: ir.IRInst) !void {
        
        switch (inst) {
            .ret => |r| {
                if (r.value) |v| {
                    switch (v) {
                        .constant => |c| try writer.print("  ret i64 {}\n", .{c}),
                        .register => |reg| try writer.print("  ret i64 %{}\n", .{reg}),
                        .float => |f| try writer.print("  ret double {d}\n", .{f}),
                        .bool_val => |b| try writer.print("  ret i1 {}\n", .{@intFromBool(b)}),
                        else => try writer.writeAll("  ret i64 0\n"),
                    }
                } else {
                    try writer.writeAll("  ret void\n");
                }
            },
            .add => |a| {
                try writer.print("  %{} = add i64 ", .{a.dest});
                try self.emitLLVMValue(writer, a.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, a.right);
                try writer.writeAll("\n");
            },
            .sub => |s| {
                try writer.print("  %{} = sub i64 ", .{s.dest});
                try self.emitLLVMValue(writer, s.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, s.right);
                try writer.writeAll("\n");
            },
            .mul => |m| {
                try writer.print("  %{} = mul i64 ", .{m.dest});
                try self.emitLLVMValue(writer, m.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, m.right);
                try writer.writeAll("\n");
            },
            .div => |d| {
                try writer.print("  %{} = sdiv i64 ", .{d.dest});
                try self.emitLLVMValue(writer, d.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, d.right);
                try writer.writeAll("\n");
            },
            .mod => |m| {
                try writer.print("  %{} = srem i64 ", .{m.dest});
                try self.emitLLVMValue(writer, m.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, m.right);
                try writer.writeAll("\n");
            },
            .neg => |n| {
                try writer.print("  %{} = sub i64 0, ", .{n.dest});
                try self.emitLLVMValue(writer, n.value);
                try writer.writeAll("\n");
            },
            .eq => |e| {
                try writer.print("  %{} = icmp eq i64 ", .{e.dest});
                try self.emitLLVMValue(writer, e.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, e.right);
                try writer.writeAll("\n");
            },
            .ne => |n| {
                try writer.print("  %{} = icmp ne i64 ", .{n.dest});
                try self.emitLLVMValue(writer, n.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, n.right);
                try writer.writeAll("\n");
            },
            .lt => |l| {
                try writer.print("  %{} = icmp slt i64 ", .{l.dest});
                try self.emitLLVMValue(writer, l.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, l.right);
                try writer.writeAll("\n");
            },
            .le => |l| {
                try writer.print("  %{} = icmp sle i64 ", .{l.dest});
                try self.emitLLVMValue(writer, l.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, l.right);
                try writer.writeAll("\n");
            },
            .gt => |g| {
                try writer.print("  %{} = icmp sgt i64 ", .{g.dest});
                try self.emitLLVMValue(writer, g.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, g.right);
                try writer.writeAll("\n");
            },
            .ge => |g| {
                try writer.print("  %{} = icmp sge i64 ", .{g.dest});
                try self.emitLLVMValue(writer, g.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, g.right);
                try writer.writeAll("\n");
            },
            .and_op => |a| {
                try writer.print("  %{} = and i64 ", .{a.dest});
                try self.emitLLVMValue(writer, a.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, a.right);
                try writer.writeAll("\n");
            },
            .or_op => |o| {
                try writer.print("  %{} = or i64 ", .{o.dest});
                try self.emitLLVMValue(writer, o.left);
                try writer.writeAll(", ");
                try self.emitLLVMValue(writer, o.right);
                try writer.writeAll("\n");
            },
            .not_op => |n| {
                try writer.print("  %{} = xor i64 ", .{n.dest});
                try self.emitLLVMValue(writer, n.value);
                try writer.writeAll(", -1\n");
            },
            .load => |l| {
                try writer.print("  %{} = load i64, i64* %{}\n", .{l.dest, l.src});
            },
            .store => |s| {
                try writer.print("  store i64 ", .{});
                try self.emitLLVMValue(writer, s.value);
                try writer.print(", i64* %{}\n", .{s.dest});
            },
            .alloca => |a| {
                try writer.print("  %{} = alloca i8, i64 {}\n", .{a.dest, a.size});
            },
            .branch => |b| {
                try writer.print("  br i1 ", .{});
                try self.emitLLVMValue(writer, b.cond);
                try writer.print(", label %block_{}, label %block_{}\n", .{b.true_label, b.false_label});
            },
            .jump => |j| {
                try writer.print("  br label %block_{}\n", .{j.label});
            },
            .label => |l| {
                try writer.print("block_{}:\n", .{l.id});
            },
            .call => |c| {
                if (c.dest) |d| {
                    try writer.print("  %{} = call i64 @{s}(", .{d, c.func});
                } else {
                    try writer.print("  call void @{s}(", .{c.func});
                }
                for (c.args, 0..) |arg, i| {
                    if (i > 0) try writer.writeAll(", ");
                    try writer.writeAll("i64 ");
                    try self.emitLLVMValue(writer, arg);
                }
                try writer.writeAll(")\n");
            },
            else => {},
        }
    }
    
    fn emitLLVMValue(_: *Compiler, writer: anytype, value: ir.IRValue) !void {
        
        switch (value) {
            .constant => |c| try writer.print("{}", .{c}),
            .register => |r| try writer.print("%{}", .{r}),
            .float => |f| try writer.print("{d}", .{f}),
            .bool_val => |b| try writer.print("{}", .{@intFromBool(b)}),
            .string => |s| try writer.print("c\"{s}\"", .{s}),
            .none => try writer.writeAll("null"),
        }
    }
};
