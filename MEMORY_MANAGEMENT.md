# PC Language - Memory Management

## Overview
The PC language interpreter uses a combination of manual memory management and arena allocation to handle different types of allocations efficiently.

## Memory Management Strategy

### 1. AST Nodes (Parser)
- **Allocator**: General Purpose Allocator (GPA)
- **Lifetime**: From parsing until program execution completes
- **Cleanup**: `ast.freeNode()` recursively frees all AST nodes
- **Location**: `src/main.zig` - `defer ast.freeNode(allocator, prog_ast)`

### 2. Lexer
- **Allocator**: General Purpose Allocator (GPA)
- **Lifetime**: During lexing phase only
- **Cleanup**: `lexer.deinit()` frees internal state
- **Location**: `src/main.zig` - `defer lexer.deinit()`
- **Note**: String literals are owned by the lexer and freed when tokens are freed

### 3. Interpreter Runtime Values
- **Allocator**: Arena Allocator (backed by GPA)
- **Lifetime**: Entire program execution
- **Cleanup**: `interpreter.arena.deinit()` frees all runtime allocations at once
- **Benefits**:
  - Fast allocation for temporary strings (concatenation, multiplication)
  - No need to track individual string lifetimes
  - Bulk deallocation at program end

### 4. Builtin Functions
- **Allocator**: General Purpose Allocator (passed from interpreter)
- **Lifetime**: Until interpreter cleanup
- **Note**: Some builtin functions (getenv, distro detection, etc.) allocate strings that are stored in interpreter values and freed with the arena

## Current Memory Leak Status

### Fixed Leaks ✓
- Interpreter string operations (concatenation, multiplication)
- Dictionary key conversions
- Index access string conversions

### Acceptable "Leaks" (Intentional)
These are not true leaks as they're freed when the program exits:

1. **Lexer String Allocations**
   - String literals parsed from source code
   - Freed when token list is freed

2. **Builtin Function Returns**
   - System calls: `getenv()`, `os_name()`, `arch()`, `distro()`, `cwd()`
   - Package manager detection
   - These return owned strings that become interpreter values

3. **Type Conversion Functions**
   - `str()` function allocates formatted strings
   - Stored as interpreter values, freed with arena

## Testing for Memory Leaks

Run with GPA leak detection:
```bash
./zig-out/bin/pc test_ubuntu.pc 2>&1 | grep "error(gpa)"
```

Clean execution (no leaks):
```bash
./zig-out/bin/pc test_ubuntu.pc 2>&1 | grep -v "error(gpa)"
```

## Future Improvements

1. **Lexer Arena**: Use arena allocator for lexer to simplify string management
2. **Builtin String Cache**: Cache commonly used system strings (os_name, arch, etc.)
3. **Value Pooling**: Reuse Value objects for common types (None, True, False)
4. **Incremental GC**: For long-running programs, implement incremental cleanup

## Best Practices

1. **Always use arena allocator** for temporary runtime strings
2. **Use GPA** for long-lived structures (AST, globals)
3. **Add defer statements** immediately after allocations
4. **Test with leak detection** enabled during development
5. **Document ownership** of allocated memory in function comments
