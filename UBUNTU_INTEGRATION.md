# PC 语言 - Ubuntu 系统互联完整指南

## 🎯 项目定位

PC 语言是专为 **Ubuntu/Linux 系统管理** 设计的现代编程语言，提供直接的系统互联能力，无需容器或虚拟化。

---

## ✅ 已实现的功能

### 1. 包管理器统一接口

自动检测并适配不同 Linux 发行版的包管理器：

```python
# 系统检测
print("发行版: " + distro())              # ubuntu, debian, fedora, arch
print("版本: " + distro_version())        # 22.04, 12, 39, etc.
print("包管理器: " + pkg_manager())       # apt, dnf, pacman

# 包管理操作
pkg_update()                              # 更新软件包列表
pkg_upgrade()                             # 升级所有软件包
pkg_install("nginx")                      # 安装软件包
pkg_remove("apache2")                     # 卸载软件包
pkg_search("python")                      # 搜索软件包
info = pkg_info("nginx")                  # 获取软件包信息
installed = pkg_list_installed()          # 列出已安装软件包
```

**支持的包管理器**:
- **APT** (Ubuntu/Debian/Kali)
- **DNF** (Fedora/RHEL)
- **Pacman** (Arch Linux)

### 2. systemd 服务管理

完整的 systemd 服务管理接口：

```python
# 服务控制
service_start("nginx")                    # 启动服务
service_stop("apache2")                   # 停止服务
service_restart("ssh")                    # 重启服务
service_reload("nginx")                   # 重新加载配置

# 服务配置
service_enable("docker")                  # 启用服务（开机自启）
service_disable("apache2")                # 禁用服务

# 服务状态
status = service_status("nginx")          # 获取服务状态 (active/inactive/failed)
enabled = service_is_enabled("nginx")     # 检查是否启用

# 服务列表和日志
all_services = service_list()             # 列出所有服务
logs = service_logs("nginx", 100)         # 获取最近 100 行日志
```

### 3. 文件系统操作

直接的文件系统访问和操作：

```python
# 文件读写
content = read_file("/etc/hosts")         # 读取文件
write_file("/tmp/test.txt", "Hello")      # 写入文件

# 文件检查
exists = file_exists("/etc/passwd")       # 检查文件是否存在
size = file_size("/var/log/syslog")       # 获取文件大小

# 目录操作
files = list_dir("/var/log")              # 列出目录内容
for i in range(len(files)):
    print(files[i])
```

### 4. 进程和命令执行

执行系统命令和管理进程：

```python
# 执行命令
output = exec("ls", ["-la", "/tmp"])      # 执行命令并获取输出
print(output)

# 环境变量
home = getenv("HOME")                     # 获取环境变量
user = getenv("USER")
path = getenv("PATH")

setenv("MY_VAR", "value")                 # 设置环境变量
```

### 5. 系统信息

获取系统信息和状态：

```python
# 系统信息
os = os_name()                            # linux
arch = arch()                             # x86_64, aarch64
distro_name = distro()                    # ubuntu, debian, fedora
version = distro_version()                # 22.04, 12, 39

# 路径和时间
current_dir = cwd()                       # 当前工作目录
ts = timestamp()                          # 当前时间戳（毫秒）

# 休眠
sleep(5)                                  # 休眠 5 秒
```

### 6. 网络操作（基础）

简单的网络请求功能：

```python
# HTTP 请求
response = http_get("https://api.github.com")
print(response)

# TCP 连接（占位符，待实现）
# tcp_connect("example.com", 80)
```

---

## 📦 安装和使用

### 安装 PC 语言

```bash
# 克隆项目
git clone https://github.com/your-username/pc-language.git
cd pc-language

# 运行安装脚本（自动检测 Ubuntu 并安装依赖）
bash install.sh

# 或手动编译
zig build -Doptimize=ReleaseFast
sudo cp zig-out/bin/pc /usr/local/bin/
```

### 验证安装

```bash
# 检查版本
pc --version

# 运行测试
pc examples/linux_system_info.pc
```

---

## 🚀 实际应用场景

### 场景 1: 自动化服务器配置

```python
#!/usr/bin/env pc
# server-setup.pc - 自动配置 Ubuntu 服务器

print("=" * 60)
print("Ubuntu Server Auto Configuration")
print("=" * 60)
print("")

# 检测系统
print("[System Info]")
print("OS: " + distro() + " " + distro_version())
print("Architecture: " + arch())
print("")

# 更新系统
print("[Updating System]")
pkg_update()
pkg_upgrade()
print("System updated!")
print("")

# 安装必要软件
print("[Installing Packages]")
packages = ["nginx", "postgresql", "redis-server", "git"]
for i in range(len(packages)):
    pkg = packages[i]
    print("Installing " + pkg + "...")
    pkg_install(pkg)
print("")

# 启动服务
print("[Starting Services]")
service_enable("nginx")
service_enable("postgresql")
service_enable("redis-server")

service_start("nginx")
service_start("postgresql")
service_start("redis-server")
print("")

# 检查服务状态
print("[Service Status]")
services = ["nginx", "postgresql", "redis-server"]
for i in range(len(services)):
    svc = services[i]
    status = service_status(svc)
    print(svc + ": " + status)

print("")
print("=" * 60)
print("Configuration Complete!")
print("=" * 60)
```

### 场景 2: 系统监控脚本

```python
#!/usr/bin/env pc
# monitor.pc - 系统监控

print("System Monitor")
print("=" * 60)

# 检查关键服务
print("[Critical Services]")
critical = ["nginx", "postgresql", "ssh"]
for i in range(len(critical)):
    svc = critical[i]
    status = service_status(svc)
    if status == "active":
        print("✓ " + svc + ": OK")
    else:
        print("✗ " + svc + ": " + status)

print("")

# 检查磁盘空间
print("[Disk Space]")
output = exec("df", ["-h", "/"])
print(output)

print("")

# 检查内存使用
print("[Memory Usage]")
output = exec("free", ["-h"])
print(output)
```

### 场景 3: 日志分析

```python
#!/usr/bin/env pc
# log-analyzer.pc - 分析 Nginx 日志

print("Nginx Log Analyzer")
print("=" * 60)

# 获取 Nginx 日志
logs = service_logs("nginx", 1000)

# 统计访问次数（简化版）
print("Recent Nginx activity:")
print(logs)

# 检查 Nginx 状态
status = service_status("nginx")
print("")
print("Nginx Status: " + status)
```

### 场景 4: 备份脚本

```python
#!/usr/bin/env pc
# backup.pc - 系统备份

print("System Backup Script")
print("=" * 60)

# 创建备份目录
backup_dir = "/backup/" + str(timestamp())
exec("mkdir", ["-p", backup_dir])

# 备份配置文件
configs = ["/etc/nginx", "/etc/postgresql", "/etc/ssh"]
for i in range(len(configs)):
    config = configs[i]
    if file_exists(config):
        print("Backing up " + config + "...")
        exec("cp", ["-r", config, backup_dir])

# 备份数据库（示例）
print("Backing up databases...")
exec("pg_dumpall", ["-U", "postgres", "-f", backup_dir + "/db.sql"])

print("")
print("Backup completed: " + backup_dir)
```

### 场景 5: 软件包管理

```python
#!/usr/bin/env pc
# package-manager.pc - 软件包管理工具

print("Package Manager")
print("=" * 60)

# 列出已安装的软件包
print("[Installed Packages]")
installed = pkg_list_installed()
print(installed)

print("")

# 搜索软件包
print("[Search Results for 'python']")
results = pkg_search("python")
print(results)

print("")

# 获取软件包信息
print("[Package Info: nginx]")
info = pkg_info("nginx")
print(info)
```

---

## 🔧 开发指南

### 添加新的系统功能

1. 在 `src/stdlib/linux/` 目录下创建新模块
2. 实现功能函数
3. 在 `src/stdlib/builtins.zig` 中注册函数
4. 重新编译：`zig build`

### 示例：添加用户管理功能

```zig
// src/stdlib/linux/users.zig
pub fn builtin_user_add(interp: *Interpreter, args: []Value) InterpreterError!Value {
    // 实现用户添加功能
}
```

```zig
// src/stdlib/builtins.zig
const linux_users = @import("linux/users.zig");

// 在 builtins map 中添加
.{ "user_add", linux_users.builtin_user_add },
```

---

## 📊 功能对比

| 功能 | 传统 Shell | PC 语言 | 优势 |
|------|-----------|---------|------|
| 包管理 | apt/dnf/pacman | pkg_install() | 统一接口 |
| 服务管理 | systemctl | service_start() | 简化命令 |
| 文件操作 | cat/echo | read_file/write_file | 更直观 |
| 跨发行版 | 需要判断 | 自动适配 | 无需关心底层 |
| 错误处理 | 复杂 | 内置 | 更可靠 |
| 代码可读性 | 中等 | 高 | Python 风格 |

---

## 🎯 下一步计划

### 即将实现的功能

1. **用户管理**
   - user_add(), user_del(), user_mod()
   - group_add(), group_del()
   - user_list(), group_list()

2. **网络配置**
   - network_list_interfaces()
   - network_set_ip()
   - network_add_route()

3. **防火墙管理**
   - firewall_allow(), firewall_block()
   - firewall_list_rules()

4. **进程管理增强**
   - process_list(), process_kill()
   - process_info(), process_monitor()

5. **定时任务**
   - cron_add(), cron_remove()
   - cron_list()

---

## 💡 最佳实践

### 1. 错误处理

```python
# 检查操作结果
result = pkg_install("nginx")
if result:
    print("安装成功")
else:
    print("安装失败")
```

### 2. 权限管理

```python
# 需要 sudo 权限的操作
# 运行时使用: sudo pc script.pc
pkg_install("nginx")
service_start("nginx")
```

### 3. 日志记录

```python
# 记录操作日志
log_file = "/var/log/pc-script.log"
timestamp_str = str(timestamp())
write_file(log_file, timestamp_str + ": Script executed\n")
```

### 4. 系统检测

```python
# 根据发行版执行不同操作
if distro() == "ubuntu":
    pkg_install("ubuntu-specific-package")
elif distro() == "fedora":
    pkg_install("fedora-specific-package")
```

---

## 🐛 故障排除

### 问题 1: 权限不足

```bash
# 解决方案：使用 sudo 运行
sudo pc your-script.pc
```

### 问题 2: 包管理器未检测

```bash
# 检查 /etc/os-release 文件
cat /etc/os-release

# 确保系统是支持的发行版
```

### 问题 3: 服务未找到

```bash
# 检查服务是否存在
systemctl list-units --type=service | grep your-service
```

---

## 📚 参考资源

### 官方文档
- [README.md](README.md) - 项目介绍
- [LINUX_VISION.md](LINUX_VISION.md) - Linux 系统互联愿景
- [ROADMAP.md](ROADMAP.md) - 开发路线图

### 示例程序
- `examples/linux_system_info.pc` - 系统信息
- `examples/linux_service_demo.pc` - 服务管理
- `examples/linux_package_demo.pc` - 包管理

### 社区
- GitHub Issues: 报告问题和建议
- GitHub Discussions: 讨论和交流

---

## 🤝 贡献

欢迎贡献代码、文档和示例！

```bash
# Fork 项目
git clone https://github.com/your-username/pc-language.git

# 创建分支
git checkout -b feature/new-function

# 提交更改
git commit -m "Add new function"

# 推送并创建 Pull Request
git push origin feature/new-function
```

---

**PC 语言 - 让 Ubuntu 系统管理更简单！** 🐧🚀
