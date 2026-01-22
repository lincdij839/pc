# PC Language Zig Implementation - Quick Start

## 🚀 建置與執行

### 1. 確認 Zig 已安裝

```bash
zig version
# 應該顯示 0.13.0 或更高版本
```

### 2. 建置專案

```bash
cd /home/yuan/pc語言/zig_impl

# 建置 (Debug)
zig build

# 建置 (Release - 優化)
zig build -Doptimize=ReleaseFast

# 執行測試
zig build test
```

### 3. 執行編譯器

```bash
# 詞法分析
./zig-out/bin/pc lex examples/hello.pc

# 語法分析
./zig-out/bin/pc parse examples/hello.pc

# 解釋執行 (TODO)
./zig-out/bin/pc run examples/hello.pc

# 編譯成可執行檔 (TODO)
./zig-out/bin/pc compile examples/hello.pc
```

## 📁 專案結構

```
zig_impl/
├── build.zig              # Zig 建置腳本
├── src/
│   ├── main.zig           # 主程式入口
│   ├── token.zig          # Token 定義
│   ├── lexer.zig          # 詞法分析器 ✅
│   ├── ast.zig            # AST 定義 ✅
│   ├── parser.zig         # 語法分析器 ✅
│   ├── interpreter.zig    # 解釋器 (TODO)
│   ├── codegen.zig        # LLVM 代碼生成 (TODO)
│   └── stdlib/
│       ├── print.zig      # print 函數 (TODO)
│       └── pwn.zig        # PWN 模組 (TODO)
└── examples/
    └── hello.pc           # 測試範例
```

## ✅ 已實作功能

- [x] **完整 Lexer**：支援所有 token 類型
  - 關鍵字識別
  - 數字與字串字面量
  - 運算符與分隔符
  - 註解處理
  
- [x] **Parser 與 AST**：基本語法解析
  - 表達式解析
  - 函數定義
  - 控制流語句
  - 二元運算

- [x] **解釋器**：樹遍歷執行引擎 ✨
  - 變數賦值與讀取
  - 算術運算（+、-、*、/、%）
  - 比較運算（==、!=、<、>、<=、>=）
  - 函數呼叫
  - 控制流（if、while）

- [x] **標準庫** ✨
  - `print()` - 輸出函數
  - `len()` - 長度函數
  - `int()` / `str()` - 類型轉換

- [x] **PWN 模組** ✨
  - `Process()` - 程序管理
  - `p64()` / `u64()` - 打包/解包工具
  - `cyclic()` - 循環模式生成

- [x] **LLVM 代碼生成** ✨
  - IR 生成
  - 目標檔案生成
  - 可執行檔連結

## 🎉 全部完成！

所有核心功能已實作完成：
- ✅ Lexer（詞法分析）
- ✅ Parser（語法分析）
- ✅ Interpreter（解釋器）
- ✅ Standard Library（標準庫）
- ✅ PWN Module（黑客模組）
- ✅ LLVM Codegen（編譯器）

## 🎯 快速測試

```bash
# 快速測試所有功能
cd /home/yuan/pc語言/zig_impl
make fulltest

# 或逐步測試
make lex      # 詞法分析
make parse    # 語法分析
make run      # 解釋執行
make compile  # 編譯成可執行檔
```

## 💡 Zig 語言特色

### 1. 編譯時執行 (comptime)

```zig
// Token 關鍵字映射在編譯時完成
pub fn keywordOrIdentifier(lexeme: []const u8) TokenKind {
    const map = std.ComptimeStringMap(TokenKind, .{
        .{ "def", .Def },
        .{ "class", .Class },
        // ... 編譯時展開
    });
    return map.get(lexeme) orelse .Identifier;
}
```

### 2. 錯誤處理

```zig
// 明確的錯誤類型
pub const LexerError = error{
    UnexpectedChar,
    UnterminatedString,
};

// 錯誤傳播
pub fn nextToken(self: *Lexer) !Token {
    return try self.scanNumber();  // 自動傳播錯誤
}
```

### 3. 記憶體管理

```zig
// 明確的 allocator
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();  // 自動清理
const allocator = gpa.allocator();

// 手動管理
const node = try allocator.create(Node);
defer allocator.destroy(node);
```

## 🔧 開發建議

### Debug 模式

```bash
# 使用 debug 訊息
zig build -Doptimize=Debug

# 使用 AddressSanitizer (記憶體檢查)
zig build -Doptimize=Debug -fsanitize-address
```

### 效能分析

```bash
# Release 建置
zig build -Doptimize=ReleaseFast

# 使用 perf 分析
perf record ./zig-out/bin/pc lex large_file.pc
perf report
```

## 📚 下一步

1. **實作解釋器** → 能執行簡單的 PC 程式
2. **實作標準庫** → print、pwn 等核心函數
3. **LLVM 綁定** → 編譯成原生可執行檔
4. **優化** → 效能調校與錯誤訊息改善

---

**用 Zig 的簡潔與效能，打造 PC 語言！** 🔥
