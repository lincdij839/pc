# PC語言 (PC Language)

一門融合 **Python 語法** 與 **C/C++ 性能** 的現代編程語言，專為黑客和系統編程設計。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Language: Zig](https://img.shields.io/badge/Language-Zig-orange.svg)](https://ziglang.org/)
[![Completion: 91%](https://img.shields.io/badge/Completion-91%25-brightgreen.svg)]()

## 🌟 核心特性

- **🐍 Python 風格語法** - 縮進式語法、無分號、直觀易讀
- **⚡ C/C++ 級性能** - 接近原生性能，支持手動內存管理
- **🔗 FFI 支持** - 直接調用 C/C++ 函數
- **🛠️ 內建黑客工具** - PWN 模組（pack/unpack、process 等）
- **📦 單文件編譯** - 編譯成獨立可執行文件
- **⚙️ HolyC 風格執行** - 直接運行，無需子命令

## 📦 安裝

### 前置需求
- Zig 0.13.0+

### 構建
```bash
git clone https://github.com/your-username/pc-language.git
cd pc-language/zig_impl
zig build
```

## 🚀 快速開始

### Hello World
```python
# hello.pc
print("Hello, PC Language!")
```

運行：
```bash
./zig-out/bin/pc hello.pc
```

### 變數和運算
```python
x = 100
y = 20
result = x + y
print(result)  # 120
```

### 函數定義
```python
def add(a, b):
    return a + b

result = add(10, 20)
print(result)  # 30
```

### 控制流
```python
x = 10
if x > 5:
    print("大於 5")
else:
    print("小於等於 5")

# while 循環
i = 0
while i < 5:
    print(i)
    i = i + 1

# for 循環
for i in range(10):
    print(i)
```

### PWN 模組
```python
# Pack/Unpack
packed = p32(0x400000)
print(len(packed))  # 4

unpacked = unpack32(packed)
print(hex(unpacked))  # 0x400000

# 十六進制轉換
addr = 0xdeadbeef
print(hex(addr))
```

## 📚 標準庫

### 基礎函數
- `print(x)` - 輸出到標準輸出
- `len(x)` - 返回長度
- `range(n)` - 生成範圍

### 類型轉換
- `str(x)` - 轉換為字串
- `int(x)` - 轉換為整數

### 數學函數
- `abs(x)` - 絕對值
- `max(a, b)` - 最大值
- `min(a, b)` - 最小值
- `pow(base, exp)` - 冪運算

### 字串函數
- `upper(s)` - 轉大寫
- `lower(s)` - 轉小寫

### PWN 模組
- `p32(value)` - 打包 32 位整數（小端）
- `p64(value)` - 打包 64 位整數（小端）
- `unpack32(bytes)` - 解包 32 位整數
- `unpack64(bytes)` - 解包 64 位整數
- `hex(value)` - 轉換為十六進制字串

## 📊 項目狀態

| 模組 | 完成度 | 狀態 |
|------|--------|------|
| Lexer | 100% | ✅ 完成 |
| Parser | 95% | ✅ 基本完成 |
| 解釋器 | 95% | ✅ 基本完成 |
| 標準庫 | 90% | ✅ 核心完成 |
| PWN 模組 | 85% | ✅ 可用 |
| LLVM 後端 | 0% | 🚧 計劃中 |

**總體完成度：91.25%**

## 🛠️ 技術架構

- **實現語言**：Zig 0.13.0
- **解釋器類型**：Tree-walking interpreter
- **內存管理**：GPA (General Purpose Allocator)
- **數據結構**：ArrayList, HashMap

## 📝 範例程序

查看 [examples/](examples/) 目錄獲取更多範例：
- `examples/hello.pc` - Hello World
- `examples/test_math.pc` - 數學函數演示
- `examples/test_string.pc` - 字串函數演示
- `examples/test_pack_simple.pc` - PWN 模組演示

## 🧪 測試

運行測試套件：
```bash
./complete_test.sh
```

運行演示腳本：
```bash
./demo.sh
```

## 📖 文檔

- [進度報告](PROGRESS.md) - 詳細的開發進度和功能清單
- [語法設計](../docs/) - 語言設計文檔

## 🤝 貢獻

歡迎貢獻！請查看待實現功能：

### 高優先級
- [ ] 完善縮進處理（INDENT/DEDENT token）
- [ ] 列表數據結構和操作
- [ ] 字典數據結構和操作

### 中優先級
- [ ] class 定義和對象系統
- [ ] 字串 split/join/replace 函數
- [ ] process 類（PWN 模組）

### 低優先級
- [ ] LLVM 後端（編譯成機器碼）
- [ ] 模組系統（import）
- [ ] 異常處理（try/except）

## 📄 許可證

MIT License - 詳見 [LICENSE](LICENSE) 文件

## 👤 作者

PC語言由 [@yuan](https://github.com/your-username) 開發

## 🙏 致謝

- [Zig](https://ziglang.org/) - 優秀的系統編程語言
- Python 社區 - 語法設計靈感
- pwntools - PWN 模組設計參考

## 📮 聯繫

- Issues: [GitHub Issues](https://github.com/your-username/pc-language/issues)
- Discussions: [GitHub Discussions](https://github.com/your-username/pc-language/discussions)

---

**注意**：PC語言目前處於早期開發階段，API 可能會發生變化。
