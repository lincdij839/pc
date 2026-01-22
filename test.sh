#!/bin/bash
# PC Language Quick Test Script

echo "=== PC Language Test Suite ==="
echo ""

echo "Test 1: Basic Printing"
echo "Code: print(42)"
echo -n "Output: "
./zig-out/bin/pc examples/basic.pc 2>/dev/null
echo ""

echo "Test 2: Variables and Arithmetic"
echo "Code: x = 10, y = 20, z = x + y, print(z)"
echo -n "Output: "
./zig-out/bin/pc examples/minimal.pc 2>/dev/null
echo ""

echo "Test 3: If/Else Control Flow"
echo "Code: if/else statements"
echo "Output:"
./zig-out/bin/pc examples/simple_if.pc 2>/dev/null
echo ""

echo "Test 4: PWN Functions"
echo "Code: hex(), p32(), int()"
echo "Output:"
./zig-out/bin/pc examples/pwn_simple.pc 2>/dev/null
echo ""

echo "Test 5: Comprehensive Test"
echo "Code: Variables, arithmetic, if, PWN functions"
echo "Output:"
./zig-out/bin/pc examples/final_test.pc 2>/dev/null
echo ""

echo "Test 6: Help Message"
./zig-out/bin/pc 2>/dev/null
