# PC 语言 - 快速开始指南

## 🚀 快速开始

### 1. 配置 SSH 密钥（首次使用必须）

```bash
# 生成 SSH 密钥对（如果还没有）
ssh-keygen -t rsa -b 4096

# 复制公钥到本地（用于测试）
ssh-copy-id yuan@localhost

# 或复制到远程服务器
ssh-copy-id user@remote-host

# 测试连接
ssh yuan@localhost
```

### 2. 运行第一个程序

创建文件 `hello_remote.pc`：

```python
# 连接到本地系统（测试）
conn = ssh_connect("localhost", "yuan")

if conn:
    print("✓ 连接成功！")
    
    # 获取主机名
    hostname = ssh_exec(conn, "hostname")
    print("主机名: " + hostname)
    
    # 获取系统信息
    distro = remote_distro(conn)
    print("发行版: " + distro)
else:
    print("✗ 连接失败")
```

运行：
```bash
./zig-out/bin/pc hello_remote.pc
```

### 3. 管理本地系统

```python
# 获取系统信息
print("操作系统: " + os_name())
print("架构: " + arch())
print("发行版: " + distro())
print("包管理器: " + pkg_manager())

# 检查文件
if file_exists("/etc/hosts"):
    print("hosts 文件存在")
    size = file_size("/etc/hosts")
    print("大小: " + str(size) + " 字节")

# 获取环境变量
home = getenv("HOME")
print("HOME: " + home)
```

### 4. 管理 LXD 容器

```python
# 列出所有容器
containers = exec("lxc", ["list", "--format", "csv", "-c", "n"])
print("容器列表:")
print(containers)

# 在容器中执行命令
result = exec("lxc", ["exec", "debian", "--", "hostname"])
print("Debian 容器主机名: " + result)

# 复制文件到容器
write_file("test.txt", "Hello from PC Language!")
exec("lxc", ["file", "push", "test.txt", "debian/tmp/"])
print("文件已复制到容器")
```

### 5. 批量管理多个系统

```python
# 定义服务器列表
servers = ["server1", "server2", "server3"]

# 批量连接
connections = []
for server in servers:
    conn = ssh_connect(server, "admin")
    if conn:
        connections = append(connections, conn)
        print("✓ 已连接: " + server)

# 批量执行命令
print("")
print("获取所有服务器的运行时间:")
for conn in connections:
    uptime = ssh_exec(conn, "uptime -p")
    print(str(conn) + ": " + uptime)
```

## 📚 常用功能示例

### 远程命令执行

```python
conn = ssh_connect("192.168.1.100", "admin")

# 系统信息
hostname = ssh_exec(conn, "hostname")
kernel = ssh_exec(conn, "uname -r")
uptime = ssh_exec(conn, "uptime")

print("主机: " + hostname)
print("内核: " + kernel)
print("运行时间: " + uptime)
```

### 文件传输

```python
conn = ssh_connect("server1", "admin")

# 上传文件
write_file("config.txt", "server_port=8080\n")
success = ssh_copy(conn, "config.txt", "/etc/app/config.txt")

if success:
    print("✓ 文件上传成功")

# 下载文件
success = ssh_download(conn, "/var/log/app.log", "app.log")

if success:
    print("✓ 文件下载成功")
    content = read_file("app.log")
    print(content)
```

### 远程包管理

```python
conn = ssh_connect("ubuntu-server", "admin")

# 自动检测并使用正确的包管理器
distro = remote_distro(conn)
print("远程系统: " + distro)

# 安装软件（自动适配 apt/dnf/pacman）
success = remote_pkg_install(conn, "nginx")

if success:
    print("✓ Nginx 安装成功")
    
    # 启动服务
    ssh_exec(conn, "sudo systemctl start nginx")
    ssh_exec(conn, "sudo systemctl enable nginx")
```

### 集群监控

```python
servers = ["web1", "web2", "db1"]

print("集群状态监控:")
print("=" * 60)

for server in servers:
    conn = ssh_connect(server, "admin")
    
    if conn:
        # CPU 使用率
        cpu = ssh_exec(conn, "top -bn1 | grep 'Cpu(s)' | awk '{print $2}'")
        
        # 内存使用率
        mem = ssh_exec(conn, "free | grep Mem | awk '{printf \"%.1f\", $3/$2 * 100.0}'")
        
        # 磁盘使用率
        disk = ssh_exec(conn, "df -h / | tail -1 | awk '{print $5}'")
        
        print(server + ":")
        print("  CPU: " + cpu + "%")
        print("  内存: " + mem + "%")
        print("  磁盘: " + disk)
        print("")
```

## 🎯 实际应用场景

### 场景 1: 批量部署配置

```python
# 创建配置文件
config = "server_name=myapp\nport=8080\nlog_level=info\n"
write_file("app.conf", config)

# 部署到所有节点
nodes = ["node1", "node2", "node3"]

for node in nodes:
    conn = ssh_connect(node, "deploy")
    
    # 上传配置
    ssh_copy(conn, "app.conf", "/etc/myapp/app.conf")
    
    # 重启服务
    ssh_exec(conn, "sudo systemctl restart myapp")
    
    print(node + " 部署完成")
```

### 场景 2: 跨系统数据备份

```python
# 主服务器
master = ssh_connect("master.example.com", "admin")

# 备份服务器
backup = ssh_connect("backup.example.com", "admin")

# 从主服务器下载数据
print("从主服务器下载数据...")
ssh_download(master, "/data/important.db", "important.db")

# 上传到备份服务器
print("上传到备份服务器...")
ssh_copy(backup, "important.db", "/backup/important.db")

print("✓ 数据备份完成")
```

### 场景 3: 多发行版统一管理

```python
# 不同发行版的服务器
ubuntu = ssh_connect("ubuntu.local", "admin")
fedora = ssh_connect("fedora.local", "admin")
arch = ssh_connect("arch.local", "admin")

servers = [ubuntu, fedora, arch]

# 在所有服务器上安装 nginx
# PC 语言会自动适配每个系统的包管理器
for server in servers:
    distro = remote_distro(server)
    print("在 " + distro + " 上安装 nginx...")
    
    success = remote_pkg_install(server, "nginx")
    
    if success:
        print("  ✓ 安装成功")
    else:
        print("  ✗ 安装失败")
```

## 🔧 故障排查

### 连接失败

```python
conn = ssh_connect("server1", "admin")

if not conn:
    print("连接失败，请检查：")
    print("1. SSH 服务是否运行")
    print("   sudo systemctl status sshd")
    print("")
    print("2. 防火墙是否允许 SSH")
    print("   sudo ufw status")
    print("")
    print("3. 密钥认证是否配置")
    print("   ssh -v admin@server1")
    print("")
    print("4. 网络是否可达")
    print("   ping server1")
```

### 命令执行失败

```python
result = ssh_exec(conn, "some-command")

if not result:
    print("命令执行失败")
    # 尝试获取错误信息
    error = ssh_exec(conn, "some-command 2>&1")
    print("错误: " + error)
```

## 📖 更多示例

查看 `examples/` 目录中的完整示例：

- `examples/multi_system_connect.pc` - 基础连接示例
- `examples/cluster_manager.pc` - 集群管理示例
- `test_remote.pc` - 功能测试
- `ubuntu_multi_system_bridge.pc` - Ubuntu 与多系统互联

## 📚 完整文档

- `MULTI_SYSTEM.md` - 完整的多系统互联文档
- `UBUNTU_INTEGRATION.md` - Ubuntu 系统集成文档
- `SUMMARY_MULTI_SYSTEM.md` - 功能总结

## 💡 提示

1. **首次使用必须配置 SSH 密钥**
2. **使用 localhost 测试功能**
3. **查看示例程序学习最佳实践**
4. **阅读完整文档了解所有功能**

开始使用 PC 语言管理你的多系统环境吧！🚀
