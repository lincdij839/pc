# PC Language Makefile (Zig Implementation)

.PHONY: all build run test clean lex parse compile help

all: build

# 建置專案
build:
	@echo "Building PC compiler..."
	zig build

# 建置 release 版本
release:
	@echo "Building PC compiler (Release)..."
	zig build -Doptimize=ReleaseFast

# 執行範例
run: build
	@echo "Running hello.pc..."
	./zig-out/bin/pc run examples/hello.pc

# 測試
test: build
	@echo "Running tests..."
	zig build test

# 測試 Lexer
lex: build
	@echo "Testing Lexer on hello.pc..."
	./zig-out/bin/pc lex examples/hello.pc

# 測試 Parser
parse: build
	@echo "Testing Parser on hello.pc..."
	./zig-out/bin/pc parse examples/hello.pc

# 測試編譯
compile: build
	@echo "Compiling test.pc..."
	./zig-out/bin/pc compile examples/test.pc

# 清理
clean:
	@echo "Cleaning build artifacts..."
	rm -rf zig-out zig-cache
	rm -f examples/*.ll examples/*.o examples/*.exe

# 完整測試
fulltest: build
	@echo "=== Testing Lexer ==="
	./zig-out/bin/pc lex examples/hello.pc
	@echo ""
	@echo "=== Testing Parser ==="
	./zig-out/bin/pc parse examples/hello.pc
	@echo ""
	@echo "=== Testing Interpreter ==="
	./zig-out/bin/pc run examples/test.pc
	@echo ""
	@echo "=== All tests passed! ==="

# 幫助
help:
	@echo "PC Language Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make build     - Build the compiler (default)"
	@echo "  make release   - Build optimized release version"
	@echo "  make run       - Run hello.pc example"
	@echo "  make test      - Run unit tests"
	@echo "  make lex       - Test lexer"
	@echo "  make parse     - Test parser"
	@echo "  make compile   - Test compiler"
	@echo "  make fulltest  - Run all tests"
	@echo "  make clean     - Clean build artifacts"
	@echo "  make help      - Show this help"
