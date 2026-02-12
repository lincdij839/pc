# PC语言 示例程序

本目录包含 PC 语言的示例程序，展示语言的各种特性。

## 📁 示例列表

### 基础示例

#### hello.pc - Hello World
最简单的入门示例，展示基本的输出功能。

```python
print("Hello, PC Language!")
```

运行：
```bash
./zig-out/bin/pc examples/hello.pc
```

## 🚀 运行示例

### 解释模式（推荐）
```bash
./zig-out/bin/pc examples/hello.pc
```

### 编译模式
```bash
./zig-out/bin/pc compile examples/hello.pc
./examples/hello.pc.out
```

## 📝 创建自己的程序

1. 创建 `.pc` 文件
2. 使用 Python 风格语法编写代码
3. 运行：`./zig-out/bin/pc your_program.pc`

### 示例模板

```python
# 变量和运算
x = 10
y = 20
print(x + y)

# 函数定义
def greet(name):
    print("Hello, " + name)

greet("World")

# 列表操作
numbers = [1, 2, 3, 4, 5]
for i in range(len(numbers)):
    print(numbers[i])

# 字典操作
person = {"name": "Alice", "age": 30}
print(person["name"])
```

## 🎯 学习路径

1. **hello.pc** - 了解基本语法
2. 创建自己的简单程序
3. 探索标准库函数
4. 尝试编译模式

## 📚 更多资源

- [README.md](../README.md) - 完整语言文档
- [PROGRESS.md](../PROGRESS.md) - 开发进度
- [QUICKSTART.md](../QUICKSTART.md) - 快速开始指南

---

**提示**：所有示例都可以直接运行，无需额外配置！
