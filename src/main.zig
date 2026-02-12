// PC Language Compiler - Main Entry Point
const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const Interpreter = @import("interpreter.zig").Interpreter;
const Codegen = @import("codegen.zig").Codegen;
const Compiler = @import("compiler.zig").Compiler;
const CompilerOptions = @import("compiler.zig").CompilerOptions;
const Token = @import("token.zig").Token;
const ast = @import("ast.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};  
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // HolyC style: if only 2 args, directly run the file
    if (args.len == 2) {
        try runFile(allocator, args[1]);
        return;
    }

    if (args.len < 3) {
        try printUsage();
        return;
    }

    const command = args[1];
    const filename = args[2];

    if (std.mem.eql(u8, command, "lex")) {
        try lexFile(allocator, filename);
    } else if (std.mem.eql(u8, command, "parse")) {
        try parseFile(allocator, filename);
    } else if (std.mem.eql(u8, command, "run")) {
        try runFile(allocator, filename);
    } else if (std.mem.eql(u8, command, "compile")) {
        try compileFile(allocator, filename);
    } else if (std.mem.eql(u8, command, "build")) {
        // 新的优化编译模式
        try buildFile(allocator, filename, args);
    } else if (std.mem.eql(u8, command, "--emit-ir")) {
        try emitIRFile(allocator, filename);
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
        try printUsage();
    }
}

fn printUsage() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(
        \\PC Language Compiler v0.2.0 (Multi-Platform)
        \\Usage: 
        \\  pc <file>              - Run the program (HolyC style, interpreter)
        \\  pc [command] <file>    - Execute specific command
        \\
        \\Commands:
        \\  lex       - Tokenize the source file
        \\  parse     - Parse and show AST
        \\  run       - Run the program (interpreter mode)
        \\  compile   - Compile to executable (legacy)
        \\  build     - Build optimized binary (NEW! 10-100x faster)
        \\  --emit-ir - Generate and show IR
        \\
        \\Build Options:
        \\  -o <file>         - Output file name
        \\  -O0               - No optimization
        \\  -O1               - Basic optimization (default)
        \\  -O2               - Full optimization
        \\  --target=<target> - Target platform (cross-compilation)
        \\
        \\Supported Targets:
        \\  x86_64-linux      - x86_64 Linux (default on x86_64 Linux)
        \\  aarch64-linux     - ARM64 Linux
        \\  arm64-linux       - ARM64 Linux (alias)
        \\  x86_64-windows    - x86_64 Windows
        \\  x86_64-macos      - x86_64 macOS
        \\  aarch64-macos     - ARM64 macOS (Apple Silicon)
        \\  arm64-macos       - ARM64 macOS (alias)
        \\  riscv64-linux     - RISC-V 64-bit Linux
        \\  wasm32            - WebAssembly 32-bit
        \\
        \\Examples:
        \\  pc hello.pc                         - Direct execution (interpreter)
        \\  pc build hello.pc                   - Compile for current platform
        \\  pc build hello.pc -o hello          - Compile with custom output name
        \\  pc build hello.pc --target=arm64-linux  - Cross-compile to ARM64
        \\  pc --emit-ir hello.pc               - Show IR representation
        \\  pc lex example.pc                   - Show tokens
        \\
        \\Platform Support:
        \\  Interpreter:  All platforms (Linux, Windows, macOS, BSD, etc.)
        \\  Compiler:     x86_64/ARM64 Linux (primary), others experimental
        \\
        \\Performance Comparison:
        \\  Interpreter mode:  1x speed (good for development)
        \\  Compiled mode:     10-100x speed (production ready)
        \\
    , .{});
}

fn lexFile(allocator: std.mem.Allocator, filename: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Lexing file: {s}\n", .{filename});

    // Read file
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const source = try file.readToEndAlloc(allocator, 10 * 1024 * 1024); // 10MB max
    defer allocator.free(source);

    // Tokenize
    var lexer = Lexer.init(allocator, source);
    defer lexer.deinit();
    const tokens = try lexer.scanAll();
    defer tokens.deinit();

    try stdout.print("Tokens found: {}\n", .{tokens.items.len});
    for (tokens.items) |tok| {
        try stdout.print("  {}\n", .{tok});
    }
}

fn parseFile(allocator: std.mem.Allocator, filename: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Parsing file: {s}\n", .{filename});

    // Read file
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const source = try file.readToEndAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(source);

    // Tokenize
    var lexer = Lexer.init(allocator, source);
    defer lexer.deinit();
    const tokens = try lexer.scanAll();
    defer tokens.deinit();

    try stdout.print("Tokens: {}\n", .{tokens.items.len});

    // Parse
    var parser = Parser.init(allocator, tokens.items);
    const prog_ast = try parser.parseProgram();
    defer ast.freeNode(allocator, prog_ast);

    try stdout.print("Parsing complete!\n", .{});
}

fn runFile(allocator: std.mem.Allocator, filename: []const u8) !void {
    // Read file
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const source = try file.readToEndAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(source);

    // Tokenize
    var lexer = Lexer.init(allocator, source);
    defer lexer.deinit();
    const tokens = try lexer.scanAll();
    defer tokens.deinit();

    // Parse
    var parser = Parser.init(allocator, tokens.items);
    const prog_ast = try parser.parseProgram();
    defer ast.freeNode(allocator, prog_ast);

    // Execute (HolyC style - no extra output)
    var interp = Interpreter.init(allocator);
    defer interp.deinit();
    
    try interp.execute(prog_ast);
}

fn compileFile(allocator: std.mem.Allocator, filename: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Compiling file: {s}\n", .{filename});

    // Read file
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const source = try file.readToEndAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(source);

    // Tokenize
    var lexer = Lexer.init(allocator, source);
    defer lexer.deinit();
    const tokens = try lexer.scanAll();
    defer tokens.deinit();

    // Parse
    var parser = Parser.init(allocator, tokens.items);
    const prog_ast = try parser.parseProgram();
    defer ast.freeNode(allocator, prog_ast);

    // Generate LLVM IR
    var codegen = try Codegen.init(allocator, "main");
    defer codegen.deinit();
    
    try codegen.generate(prog_ast);
    
    // Emit IR file
    const ir_file = try std.fmt.allocPrint(allocator, "{s}.ll", .{filename});
    defer allocator.free(ir_file);
    try codegen.emitIR(ir_file);
    
    // Emit object file
    const obj_file = try std.fmt.allocPrint(allocator, "{s}.o", .{filename});
    defer allocator.free(obj_file);
    try codegen.emitObject(obj_file);
    
    // Link to executable
    const exe_file = try std.fmt.allocPrint(allocator, "{s}.out", .{filename});
    defer allocator.free(exe_file);
    try Codegen.link(allocator, obj_file, exe_file);
    
    try stdout.print("[✓] Compilation complete: {s}\n", .{exe_file});
}

test "basic lexer test" {
    const allocator = std.testing.allocator;
    const source = "def main(): return 42";

    var lexer = Lexer.init(allocator, source);
    defer lexer.deinit();
    const tokens = try lexer.scanAll();
    defer tokens.deinit();

    try std.testing.expect(tokens.items.len > 0);
}


// 新的优化编译模式
fn buildFile(allocator: std.mem.Allocator, filename: []const u8, args: [][]const u8) !void {
    var options = CompilerOptions{
        .emit_ir = false,
        .emit_asm = false,
        .optimize = true,
        .output_file = null,
        .target = null,
    };
    
    // 解析命令行选项
    var i: usize = 3;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "-o") and i + 1 < args.len) {
            options.output_file = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, args[i], "-O0")) {
            options.optimize = false;
        } else if (std.mem.eql(u8, args[i], "--emit-ir")) {
            options.emit_ir = true;
        } else if (std.mem.eql(u8, args[i], "--emit-asm")) {
            options.emit_asm = true;
        } else if (std.mem.eql(u8, args[i], "--target") and i + 1 < args.len) {
            options.target = args[i + 1];
            i += 1;
        } else if (std.mem.startsWith(u8, args[i], "--target=")) {
            options.target = args[i]["--target=".len..];
        }
    }
    
    var compiler = try Compiler.init(allocator, options);
    defer compiler.deinit();
    
    try compiler.compileFile(filename);
}

// 生成并显示 IR
fn emitIRFile(allocator: std.mem.Allocator, filename: []const u8) !void {
    const options = CompilerOptions{
        .emit_ir = true,
        .emit_asm = false,
        .optimize = false,
        .output_file = null,
    };
    
    var compiler = try Compiler.init(allocator, options);
    defer compiler.deinit();
    
    try compiler.compileFile(filename);
}
