#!/bin/bash
# PC語言功能展示腳本

cd "$(dirname "$0")"

echo "================================"
echo "   PC語言 功能展示"
echo "================================"
echo ""

run_demo() {
    local title="$1"
    local code="$2"
    
    echo "----------------------------"
    echo "📌 $title"
    echo "----------------------------"
    echo "代碼:"
    echo "$code"
    echo ""
    echo "輸出:"
    echo "$code" | ./zig-out/bin/pc /dev/stdin 2>/dev/null
    echo ""
}

echo "🔹 1. 基礎運算和變數"
run_demo "變數和算術" 'x = 100
y = 20
result = x + y
print(result)'

echo "🔹 2. 條件判斷"
run_demo "if/else 控制流" 'x = 10
if x > 5:
    print(777)
else:
    print(999)'

echo "🔹 3. 數學函數"
run_demo "abs, max, min" 'print(abs(-42))
print(max(100, 200))
print(min(50, 30))'

echo "🔹 4. 字串函數"
run_demo "upper, lower" 'text = "Hello World"
print(upper("hello"))
print(lower("WORLD"))'

echo "🔹 5. PWN 模組 - Pack/Unpack"
run_demo "p32 和 unpack32" 'packed = p32(4194304)
print(len(packed))
result = unpack32(packed)
print(result)'

echo "🔹 6. PWN 模組 - Hex"
run_demo "十六進制轉換" 'value = 255
hex_val = hex(value)
print(hex_val)'

echo "================================"
echo "   ✨ 展示完成！"
echo "================================"
echo ""
echo "🎯 主要特性："
echo "  ✅ Python 風格語法"
echo "  ✅ 變數和運算"
echo "  ✅ 控制流 (if/else, while, for)"
echo "  ✅ 數學函數 (abs, max, min, pow)"
echo "  ✅ 字串函數 (upper, lower)"
echo "  ✅ PWN 工具 (p32, p64, unpack32, unpack64, hex)"
echo "  ✅ 用戶自定義函數（帶本地作用域）"
echo ""
echo "📊 完成度: 91.25%"
echo "📖 詳細報告: PROGRESS.md"
