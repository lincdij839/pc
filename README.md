# PC语言 (PC Language)

一门专为 **Ubuntu/Linux 系统管理** 设计的现代编程语言，提供直接的系统互联能力。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Language: Zig](https://img.shields.io/badge/Language-Zig-orange.svg)](https://ziglang.org/)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)]()
[![Completion: 85%](https://img.shields.io/badge/Completion-85%25-brightgreen.svg)]()

## 🎯 专为 Ubuntu/Linux 设计

PC 语言直接在 Ubuntu 系统上运行，无需容器或虚拟化，提供简洁的 Python 风格语法和强大的系统管理能力。

### 支持的发行版
- 🐧 **Ubuntu** - 主要支持平台
- 🐧 **Debian** - 完全兼容
- 🎩 **Fedora/RHEL** - 企业级应用
- 🏔️ **Arch Linux** - 滚动更新
- 🔐 **Kali Linux** - 安全测试
- 🦎 **openSUSE** - 企业级稳定性

## 🌟 核心特性

- **🐍 Python 风格语法** - 缩进式语法、无分号、直观易读
- **⚡ 接近原生性能** - 用 Zig 实现，编译成高效机器码
- **🐧 直接系统访问** - 无需容器，直接操作 Ubuntu 系统
- **🔧 systemd 集成** - 原生支持 systemd 服务管理
- **📦 包管理器统一** - 自动适配 apt/dnf/pacman/zypper
- **🌐 多系统互联** - SSH 远程管理、集群协调、批量部署
- **🛠️ 系统工具集成** - 文件、进程、网络、服务管理
- **⚙️ 简单易用** - 直接运行 `pc script.pc`

## 📦 安装

### 前置需求
- Zig 0.13.0+

### 构建
```bash
git clone https://github.com/your-username/pc-language.git
cd pc-language
zig build
```

## 🚀 快速开始

### Hello World
```python
# hello.pc
print("Hello, PC Language!")
```

运行（解释模式）：
```bash
./zig-out/bin/pc hello.pc
```

编译成可执行文件（LLVM）：
```bash
./zig-out/bin/pc compile hello.pc
./hello.pc.out
```

### 变量和运算
```python
x = 100
y = 20
result = x + y
print(result)  # 120
```

### 函数定义
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
    print("大于 5")
else:
    print("小于等于 5")

# while 循环
i = 0
while i < 5:
    print(i)
    i = i + 1

# for 循环
for i in range(10):
    print(i)
```

### Linux 系统互联
```python
# 包管理器统一接口（自动适配 apt/dnf/pacman）
print("Distribution: " + distro())
print("Package Manager: " + pkg_manager())

# 搜索和安装软件包
pkg_search("nginx")
pkg_install("nginx")

# systemd 服务管理
service_start("nginx")
service_enable("nginx")
status = service_status("nginx")
print("Nginx status: " + status)

# 查看服务日志
logs = service_logs("nginx", 50)
print(logs)
```

### 系统信息和文件操作
```python
# 系统信息
print("OS: " + os_name())
print("Arch: " + arch())
print("CWD: " + cwd())

# 文件操作
content = read_file("/etc/hosts")
write_file("/tmp/test.txt", "Hello Linux!")

# 目录列表
files = list_dir("/var/log")
for i in range(len(files)):
    print(files[i])

# 执行命令
output = exec("ls", ["-la", "/tmp"])
print(output)
```
```python
# 列表操作
nums = [1, 2, 3]
nums[0] = 999
print(nums[0])  # 999
nums = append(nums, 4)
print(len(nums))  # 4

# 字典操作
config = {"host": "localhost", "port": 8080}
config["host"] = "192.168.1.1"
```

### 多系统互联 🌐
```python
# 连接到远程 Linux 系统
conn = ssh_connect("192.168.1.100", "admin")

if conn:
    # 执行远程命令
    hostname = ssh_exec(conn, "hostname")
    print("Remote host: " + hostname)
    
    # 获取远程系统信息
    distro = remote_distro(conn)
    print("Remote distro: " + distro)
    
    # 在远程系统安装软件（自动适配包管理器）
    remote_pkg_install(conn, "nginx")
    
    # 文件传输
    ssh_copy(conn, "config.txt", "/etc/app/config.txt")
    ssh_download(conn, "/var/log/app.log", "app.log")
    
    # 批量管理多个服务器
    servers = ["server1", "server2", "server3"]
    for server in servers:
        conn = ssh_connect(server, "admin")
        ssh_exec(conn, "systemctl restart nginx")
        print(server + " restarted")
```
print(config["host"])  # 192.168.1.1
print(keys(config))  # ["host", "port"]
```

## 📚 标准库

### 基础函数
- `print(x)` - 输出到标准输出
- `len(x)` - 返回长度（支持字符串、列表、字典）
- `range(n)` - 生成范围

### 类型转换
- `str(x)` - 转换为字符串
- `int(x)` - 转换为整数

### 数学函数
- `abs(x)` - 绝对值
- `max(a, b)` - 最大值
- `min(a, b)` - 最小值
- `pow(base, exp)` - 幂运算

### 字符串函数
- `upper(s)` - 转大写
- `lower(s)` - 转小写
- `split(s, sep)` - 分割字符串
- `join(list, sep)` - 连接字符串
- `replace(s, old, new)` - 替换
- `strip(s)` - 去除首尾空白
- `startswith(s, prefix)` - 检查前缀
- `endswith(s, suffix)` - 检查后缀
- `find(s, sub)` - 查找子串
- `chr(n)` - 数字转字符
- `ord(c)` - 字符转数字

### 列表函数
- `append(list, item)` - 添加元素（返回新列表）

### 字典函数
- `keys(dict)` - 返回键列表
- `values(dict)` - 返回值列表

### 数字字面量
- `0x...` - 十六进制（例：0x401234）
- `0o...` - 八进制（例：0o755）
- `0b...` - 二进制（例：0b1010）

## 📊 项目状态

| 模块 | 完成度 | 状态 |
|------|--------|------|
| Lexer | 100% | ✅ 完成 |
| Parser | 98% | ✅ 完成 |
| 解释器 | 98% | ✅ 完成 |
| 标准库 | 90% | ✅ 完成 |
| 文件操作 | 100% | ✅ 完成 |
| 数据结构 | 95% | ✅ 列表/字典完成 |
| **LLVM 后端** | **35%** | **� 已实现** |

**总体完成度：85%**

## 🛠️ 技术架构

- **实现语言**：Zig 0.13.0
- **解释器类型**：Tree-walking interpreter
- **内存管理**：GPA (General Purpose Allocator)
- **数据结构**：ArrayList, HashMap

## 📝 范例程序

查看 [examples/](examples/) 目录获取更多范例：

- `hello.pc` - Hello World 入门示例

## 🧪 测试

运行测试套件：
```bash
./complete_test.sh
```

运行演示脚本：
```bash
./demo.sh
```

## 📖 文档

- [进度报告](PROGRESS.md) - 详细的开发进度和功能清单
- [快速开始](QUICKSTART.md) - 快速上手指南

## 🤝 贡献

欢迎贡献！请查看待实现功能：

### 高优先级
- [ ] 完善缩进处理（INDENT/DEDENT token）
- [ ] 更多字符串操作函数
- [ ] 文件 I/O 操作

### 中优先级
- [ ] class 定义和对象系统
- [ ] 模块系统（import）
- [ ] 列表切片语法（list[1:3]）

### 低优先级
- [ ] LLVM 后端优化（编译成机器码）
- [ ] 异常处理（try/except）
- [ ] 类型标注系统

### ✅ 已完成
- [x] 列表数据结构和操作
- [x] 字典数据结构和操作
- [x] 字典/列表索引赋值（dict[key] = value）
- [x] 十六进制/八进制/二进制字面量
- [x] 字符串拼接和字符串乘法（"=" * 60）
- [x] **LLVM 编译器后端**（生成原生 machine code）

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 👤 作者

PC语言由 [@yuan](https://github.com/your-username) 开发

## 🙏 致谢

- [Zig](https://ziglang.org/) - 优秀的系统编程语言
- Python 社区 - 语法设计灵感

## 📮 联系

- Issues: [GitHub Issues](https://github.com/your-username/pc-language/issues)
- Discussions: [GitHub Discussions](https://github.com/your-username/pc-language/discussions)

---

**注意**：PC语言目前处于早期开发阶段，API 可能会发生变化。
