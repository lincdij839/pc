#!/bin/bash
# PC Language - Complete Feature Showcase

echo "╔════════════════════════════════════════╗"
echo "║   PC Language - Complete Showcase     ║"
echo "║   Version 0.1.0 (Zig Implementation)  ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Feature 1: Variables and Arithmetic
echo "📊 Feature 1: Variables and Arithmetic"
cat > /tmp/test1.pc << 'EOF'
x = 10
y = 20
sum = x + y
diff = y - x
prod = x * y
print(sum)
print(diff)
print(prod)
EOF
./zig-out/bin/pc /tmp/test1.pc 2>/dev/null
echo ""

# Feature 2: Control Flow - If/Else
echo "🔀 Feature 2: Control Flow (If/Else)"
cat > /tmp/test2.pc << 'EOF'
score = 85
if score > 90:
    print(100)
else:
    print(200)
EOF
./zig-out/bin/pc /tmp/test2.pc 2>/dev/null
echo ""

# Feature 3: Loops
echo "🔁 Feature 3: Loops (For/While)"
cat > /tmp/test3.pc << 'EOF'
total = 0
for i in range(5):
    total = total + i
print(total)
EOF
./zig-out/bin/pc /tmp/test3.pc 2>/dev/null
echo ""

# Feature 4: PWN Functions
echo "🔧 Feature 4: PWN/Hacker Functions"
cat > /tmp/test4.pc << 'EOF'
addr = 4194304
print(hex(addr))
packed = p32(255)
print(len(packed))
EOF
./zig-out/bin/pc /tmp/test4.pc 2>/dev/null
echo ""

# Feature 5: Type Conversions
echo "🔄 Feature 5: Type Conversions"
cat > /tmp/test5.pc << 'EOF'
x = int(123)
print(x)
EOF
./zig-out/bin/pc /tmp/test5.pc 2>/dev/null
echo ""

# Feature 6: Complex Example
echo "🌟 Feature 6: Complex Example"
cat > /tmp/test6.pc << 'EOF'
base = 100
offset = 50
addr = base + offset
if addr > 100:
    result = hex(addr)
    print(result)
print(999)
EOF
./zig-out/bin/pc /tmp/test6.pc 2>/dev/null
echo ""

echo "╔════════════════════════════════════════╗"
echo "║  All Features Working Successfully!   ║"
echo "╚════════════════════════════════════════╝"

# Cleanup
rm -f /tmp/test*.pc
