// PC Language LLVM Code Generator (Stub version)
const std = @import("std");
const ast = @import("ast.zig");
const Node = ast.Node;

// LLVM C API 綁定（暫時註釋，需要 LLVM 開發庫）
// const c = @cImport({
//     @cInclude("llvm-c/Core.h");
//     @cInclude("llvm-c/Analysis.h");
//     @cInclude("llvm-c/ExecutionEngine.h");
//     @cInclude("llvm-c/Target.h");
//     @cInclude("llvm-c/TargetMachine.h");
// });

pub const CodegenError = error{
    InitializationFailed,
    CodegenFailed,
    VerificationFailed,
    OutOfMemory,
};

pub const Codegen = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, module_name: []const u8) !Codegen {
        _ = module_name;
        std.debug.print("[Codegen] Stub mode (LLVM not linked)\n", .{});
        return Codegen{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Codegen) void {
        _ = self;
    }

    pub fn generate(self: *Codegen, program: *Node) !void {
        _ = self;
        _ = program;
        std.debug.print("[Codegen] Code generation skipped (stub mode)\n", .{});
    }

    pub fn emitIR(self: *Codegen, filename: []const u8) !void {
        _ = self;
        std.debug.print("[Codegen] Would emit IR to: {s}\n", .{filename});
    }

    pub fn emitObject(self: *Codegen, filename: []const u8) !void {
        _ = self;
        std.debug.print("[Codegen] Would emit object to: {s}\n", .{filename});
    }

    pub fn link(allocator: std.mem.Allocator, object_file: []const u8, output_file: []const u8) !void {
        _ = allocator;
        _ = object_file;
        std.debug.print("[Codegen] Would link to: {s}\n", .{output_file});
    }
};
