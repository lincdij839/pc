// PC Language - Forensics & Analysis Module
const std = @import("std");
const Interpreter = @import("../interpreter.zig").Interpreter;
const Value = @import("../interpreter.zig").Value;
const InterpreterError = @import("../interpreter.zig").InterpreterError;

// ============================================================================
// File Analysis
// ============================================================================

// detect_filetype(path) - Detect file type by magic bytes
pub fn builtin_detect_filetype(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "unknown" };
    }
    
    const path = args[0].String;
    const file = std.fs.cwd().openFile(path, .{}) catch return Value{ .String = "error" };
    defer file.close();
    
    var magic: [8]u8 = undefined;
    const bytes_read = file.read(&magic) catch return Value{ .String = "error" };
    if (bytes_read < 4) return Value{ .String = "unknown" };
    
    // Check common file signatures
    if (std.mem.eql(u8, magic[0..4], &[_]u8{0x89, 0x50, 0x4E, 0x47})) {
        return Value{ .String = try interp.allocator.dupe(u8, "PNG") };
    }
    if (std.mem.eql(u8, magic[0..2], &[_]u8{0xFF, 0xD8})) {
        return Value{ .String = try interp.allocator.dupe(u8, "JPEG") };
    }
    if (std.mem.eql(u8, magic[0..4], &[_]u8{0x50, 0x4B, 0x03, 0x04})) {
        return Value{ .String = try interp.allocator.dupe(u8, "ZIP") };
    }
    if (std.mem.eql(u8, magic[0..4], &[_]u8{0x7F, 0x45, 0x4C, 0x46})) {
        return Value{ .String = try interp.allocator.dupe(u8, "ELF") };
    }
    if (std.mem.eql(u8, magic[0..2], &[_]u8{0x4D, 0x5A})) {
        return Value{ .String = try interp.allocator.dupe(u8, "PE/EXE") };
    }
    if (std.mem.eql(u8, magic[0..3], &[_]u8{0x1F, 0x8B, 0x08})) {
        return Value{ .String = try interp.allocator.dupe(u8, "GZIP") };
    }
    
    return Value{ .String = try interp.allocator.dupe(u8, "unknown") };
}

// get_magic_bytes(data, count) - Get first N bytes as hex
pub fn builtin_get_magic_bytes(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "" };
    }
    
    const data = args[0].String;
    var count: usize = 4;
    if (args.len >= 2 and args[1] == .Int) {
        count = @intCast(args[1].Int);
    }
    
    if (count > data.len) count = data.len;
    
    const result = try std.fmt.allocPrint(interp.allocator, "{x}", 
        .{std.fmt.fmtSliceHexLower(data[0..count])});
    
    return Value{ .String = result };
}

// ============================================================================
// String Extraction
// ============================================================================

// strings_extract(data, min_length) - Extract printable strings
pub fn builtin_strings_extract(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .List = std.ArrayList(Value).init(interp.allocator) };
    }
    
    const data = args[0].String;
    var min_len: usize = 4;
    if (args.len >= 2 and args[1] == .Int) {
        min_len = @intCast(args[1].Int);
    }
    
    var result = std.ArrayList(Value).init(interp.allocator);
    var current_string = std.ArrayList(u8).init(interp.allocator);
    defer current_string.deinit();
    
    for (data) |byte| {
        if (std.ascii.isPrint(byte)) {
            try current_string.append(byte);
        } else {
            if (current_string.items.len >= min_len) {
                const str = try interp.allocator.dupe(u8, current_string.items);
                try result.append(Value{ .String = str });
            }
            current_string.clearRetainingCapacity();
        }
    }
    
    // Check last string
    if (current_string.items.len >= min_len) {
        const str = try interp.allocator.dupe(u8, current_string.items);
        try result.append(Value{ .String = str });
    }
    
    return Value{ .List = result };
}

// hex_dump(data, offset, length) - Hex dump display
pub fn builtin_hex_dump(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "" };
    }
    
    const data = args[0].String;
    var offset: usize = 0;
    var length: usize = data.len;
    
    if (args.len >= 2 and args[1] == .Int) {
        offset = @intCast(args[1].Int);
    }
    if (args.len >= 3 and args[2] == .Int) {
        length = @intCast(args[2].Int);
        if (offset + length > data.len) {
            length = data.len - offset;
        }
    }
    
    var result = std.ArrayList(u8).init(interp.allocator);
    const slice = data[offset..offset+length];
    
    var i: usize = 0;
    while (i < slice.len) : (i += 16) {
        // Address
        const addr_str = try std.fmt.allocPrint(interp.allocator, "{x:0>8}  ", .{offset + i});
        defer interp.allocator.free(addr_str);
        try result.appendSlice(addr_str);
        
        // Hex bytes
        var j: usize = 0;
        while (j < 16) : (j += 1) {
            if (i + j < slice.len) {
                const hex_str = try std.fmt.allocPrint(interp.allocator, "{x:0>2} ", .{slice[i + j]});
                defer interp.allocator.free(hex_str);
                try result.appendSlice(hex_str);
            } else {
                try result.appendSlice("   ");
            }
            if (j == 7) try result.append(' ');
        }
        
        // ASCII representation
        try result.appendSlice(" |");
        j = 0;
        while (j < 16 and i + j < slice.len) : (j += 1) {
            const c = slice[i + j];
            if (std.ascii.isPrint(c)) {
                try result.append(c);
            } else {
                try result.append('.');
            }
        }
        try result.appendSlice("|\n");
    }
    
    return Value{ .String = try result.toOwnedSlice() };
}

// ============================================================================
// Archive Operations (using external tools)
// ============================================================================

// extract_zip(path, password, output_dir) - Extract ZIP archive
pub fn builtin_extract_zip(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .Bool = false };
    }
    
    const path = args[0].String;
    var password: ?[]const u8 = null;
    var output_dir: []const u8 = ".";
    
    if (args.len >= 2 and args[1] == .String) {
        password = args[1].String;
    }
    if (args.len >= 3 and args[2] == .String) {
        output_dir = args[2].String;
    }
    
    var cmd = std.ArrayList([]const u8).init(interp.allocator);
    defer cmd.deinit();
    
    try cmd.append("unzip");
    if (password) |pwd| {
        try cmd.append("-P");
        try cmd.append(pwd);
    }
    try cmd.append(path);
    try cmd.append("-d");
    try cmd.append(output_dir);
    
    var child = std.process.Child.init(cmd.items, interp.allocator);
    _ = child.spawnAndWait() catch return Value{ .Bool = false };
    
    return Value{ .Bool = true };
}

// ============================================================================
// LSB Steganography
// ============================================================================

// extract_lsb_simple(image_path) - Simple LSB extraction (via Python)
pub fn builtin_extract_lsb(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "" };
    }
    
    const image_path = args[0].String;
    
    const script = try std.fmt.allocPrint(interp.allocator,
        \\from PIL import Image
        \\import sys
        \\try:
        \\    img = Image.open('{s}')
        \\    pixels = img.load()
        \\    width, height = img.size
        \\    result = []
        \\    for y in range(height):
        \\        for x in range(width):
        \\            pixel = pixels[x, y]
        \\            if isinstance(pixel, int):
        \\                result.append(str(pixel & 1))
        \\            else:
        \\                result.append(str(pixel[0] & 1))
        \\    bits = ''.join(result)
        \\    chars = [bits[i:i+8] for i in range(0, len(bits), 8)]
        \\    text = ''.join([chr(int(c, 2)) for c in chars if len(c) == 8])
        \\    print(text[:1000])  # First 1000 chars
        \\except Exception as e:
        \\    print(f"Error: {{e}}")
    , .{image_path});
    defer interp.allocator.free(script);
    
    const result = executePythonScript(interp.allocator, script) catch 
        return Value{ .String = "" };
    
    return Value{ .String = result };
}

// ============================================================================
// Network Analysis
// ============================================================================

// parse_pcap_simple(path) - Simple PCAP parsing (via tshark)
pub fn builtin_parse_pcap(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "" };
    }
    
    const path = args[0].String;
    
    var child = std.process.Child.init(
        &[_][]const u8{"tshark", "-r", path, "-T", "fields", "-e", "frame.number", "-e", "ip.src", "-e", "ip.dst"},
        interp.allocator
    );
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Ignore;
    
    child.spawn() catch return Value{ .String = "Error: tshark not found" };
    
    const stdout = child.stdout.?.readToEndAlloc(interp.allocator, 10 * 1024 * 1024) catch 
        return Value{ .String = "" };
    
    _ = child.wait() catch return Value{ .String = "" };
    
    return Value{ .String = stdout };
}

// ============================================================================
// Helper Functions
// ============================================================================

fn executePythonScript(allocator: std.mem.Allocator, script: []const u8) ![]u8 {
    const temp_path = "/tmp/pc_forensics_script.py";
    {
        const file = try std.fs.cwd().createFile(temp_path, .{});
        defer file.close();
        try file.writeAll(script);
    }
    
    var child = std.process.Child.init(&[_][]const u8{"python3", temp_path}, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    
    try child.spawn();
    
    const stdout = try child.stdout.?.readToEndAlloc(allocator, 10 * 1024 * 1024);
    _ = try child.wait();
    
    return stdout;
}
