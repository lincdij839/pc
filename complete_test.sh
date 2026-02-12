#!/bin/bash
# PC Language Complete Test Suite

cd "$(dirname "$0")"

echo "================================"
echo "PC語言 完整測試套件"
echo "================================"
echo ""

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

run_test() {
    local test_name="$1"
    local test_file="$2"
    local expected_output="$3"
    
    echo -n "測試: $test_name ... "
    
    output=$(./zig-out/bin/pc "$test_file" 2>/dev/null)
    
    if [ "$output" == "$expected_output" ]; then
        echo -e "${GREEN}✓ 通過${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ 失敗${NC}"
        echo "  期望輸出: $expected_output"
        echo "  實際輸出: $output"
        ((FAILED++))
    fi
}

echo "=== 1. 基礎功能測試 ==="

# Test 1: 變數和算術運算
cat > /tmp/test1.pc << 'EOF'
x = 100
y = 20
z = x + y
print(z)
print(888)
EOF
run_test "變數和算術運算" "/tmp/test1.pc" "120
888"

# Test 2: 控制流 - if/else
cat > /tmp/test2.pc << 'EOF'
x = 10
if x > 5:
    print(777)
else:
    print(999)
print(666)
EOF
run_test "if/else 控制流" "/tmp/test2.pc" "777
666"

# Test 3: while 循環
cat > /tmp/test3.pc << 'EOF'
i = 0
while i < 3:
    i = i + 1
print(i)
print(555)
EOF
run_test "while 循環" "/tmp/test3.pc" "3
555"

# Test 4: for 循環
cat > /tmp/test4.pc << 'EOF'
sum = 0
for i in range(5):
    sum = sum + i
print(sum)
print(444)
EOF
run_test "for 循環" "/tmp/test4.pc" "10
444"

echo ""
echo "=== 2. 標準庫函數測試 ==="

# Test 5: 數學函數
cat > /tmp/test5.pc << 'EOF'
print(abs(5))
print(max(100, 200))
print(min(50, 30))
EOF
run_test "數學函數 (abs, max, min)" "/tmp/test5.pc" "5
200
30"

# Test 6: 字串函數
cat > /tmp/test6.pc << 'EOF'
print(upper("hello"))
print(lower("WORLD"))
EOF
run_test "字串函數 (upper, lower)" "/tmp/test6.pc" "HELLO
world"

# Test 7: 類型轉換
cat > /tmp/test7.pc << 'EOF'
num = 42
s = str(num)
print(s)
i = int(999)
print(i)
EOF
run_test "類型轉換 (str, int)" "/tmp/test7.pc" "42
999"

echo ""
echo "=== 3. PWN 模組測試 ==="

# Test 8: p32/p64 打包
cat > /tmp/test8.pc << 'EOF'
packed32 = p32(4194304)
print(len(packed32))
packed64 = p64(1234567890)
print(len(packed64))
EOF
run_test "p32/p64 打包" "/tmp/test8.pc" "4
8"

# Test 9: unpack32/unpack64 解包
cat > /tmp/test9.pc << 'EOF'
packed = p32(305419896)
result = unpack32(packed)
print(result)
EOF
run_test "unpack32 解包" "/tmp/test9.pc" "305419896"

# Test 10: hex 十六進制轉換
cat > /tmp/test10.pc << 'EOF'
value = 255
hex_str = hex(value)
print(hex_str)
EOF
run_test "hex 十六進制轉換" "/tmp/test10.pc" "0xff"

echo ""
echo "=== 4. 函數定義測試 ==="

# Test 11: 簡單函數
cat > /tmp/test11.pc << 'EOF'
def add(a, b):
    c = a + b
    return c

result = add(5, 10)
print(result)
EOF
run_test "簡單函數定義和呼叫" "/tmp/test11.pc" "15"

# Test 12: 多參數函數
cat > /tmp/test12.pc << 'EOF'
def multiply(x, y):
    result = x * y
    return result

res = multiply(6, 7)
print(res)
EOF
run_test "多參數函數" "/tmp/test12.pc" "42"

echo ""
echo "================================"
echo "測試總結"
echo "================================"
echo -e "通過: ${GREEN}${PASSED}${NC}"
echo -e "失敗: ${RED}${FAILED}${NC}"
echo "總計: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ 所有測試通過！${NC}"
    exit 0
else
    echo -e "${RED}✗ 有測試失敗${NC}"
    exit 1
fi
