# PC Language - 多系统互联功能

## 概述

PC 语言提供了强大的多系统互联功能，可以轻松管理和协调多个 Linux 系统（Ubuntu、Debian、Fedora、Arch、Kali 等）。

## 核心功能

### 1. SSH 连接管理

#### `ssh_connect(host, user) -> connection_id`
连接到远程 Linux 系统

```python
# 连接到远程服务器
conn = ssh_connect("192.168.1.100", "admin")

if conn:
    print("连接成功: " + str(conn))
else:
    print("连接失败")
```

**参数：**
- `host`: 远程主机地址（IP 或域名）
- `user`: SSH 用户名

**返回值：**
- 成功：返回连接标识符字符串（格式：`user@host`）
- 失败：返回 `false`

**前提条件：**
- 远程系统已安装并启动 SSH 服务
- 已配置 SSH 密钥认证（推荐）或密码认证

### 2. 远程命令执行

#### `ssh_exec(connection_id, command) -> output`
在远程系统上执行命令

```python
conn = ssh_connect("server1", "root")

# 获取主机名
hostname = ssh_exec(conn, "hostname")
print("远程主机: " + hostname)

# 查看系统负载
uptime = ssh_exec(conn, "uptime")
print("系统运行时间: " + uptime)

# 检查磁盘使用
disk = ssh_exec(conn, "df -h /")
print(disk)
```

**参数：**
- `connection_id`: 由 `ssh_connect()` 返回的连接标识符
- `command`: 要执行的 shell 命令

**返回值：**
- 命令的标准输出（字符串）
- 失败返回 `None`

### 3. 文件传输

#### `ssh_copy(connection_id, local_path, remote_path) -> success`
上传文件到远程系统

```python
conn = ssh_connect("server1", "admin")

# 上传配置文件
success = ssh_copy(conn, "config.txt", "/etc/myapp/config.txt")

if success:
    print("文件上传成功")
else:
    print("文件上传失败")
```

#### `ssh_download(connection_id, remote_path, local_path) -> success`
从远程系统下载文件

```python
# 下载日志文件
success = ssh_download(conn, "/var/log/app.log", "app.log")

if success:
    print("文件下载成功")
    content = read_file("app.log")
    print(content)
```

#### `sync_file(connection_id, local_path, remote_path) -> success`
使用 rsync 同步文件（支持增量同步）

```python
# 同步整个目录
success = sync_file(conn, "/local/data/", "/remote/backup/")

if success:
    print("文件同步完成")
```

### 4. 远程系统信息

#### `remote_distro(connection_id) -> distro_name`
获取远程系统的 Linux 发行版

```python
conn = ssh_connect("server1", "admin")
distro = remote_distro(conn)

print("远程系统: " + distro)  # 输出: ubuntu, debian, fedora, arch, 等
```

### 5. 远程包管理

#### `remote_pkg_install(connection_id, package_name) -> success`
在远程系统上安装软件包（自动检测包管理器）

```python
conn = ssh_connect("ubuntu-server", "admin")

# 自动使用 apt/dnf/pacman 安装
success = remote_pkg_install(conn, "nginx")

if success:
    print("Nginx 安装成功")
    
    # 启动服务
    ssh_exec(conn, "sudo systemctl start nginx")
```

## 使用场景

### 场景 1：集群监控

```python
# 监控多个服务器
servers = [
    "admin@web1.example.com",
    "admin@web2.example.com",
    "admin@db1.example.com"
]

for server in servers:
    conn = ssh_connect(server, "admin")
    
    if conn:
        cpu = ssh_exec(conn, "top -bn1 | grep 'Cpu(s)' | awk '{print $2}'")
        mem = ssh_exec(conn, "free -m | grep Mem | awk '{print $3/$2 * 100.0}'")
        
        print(server + ":")
        print("  CPU: " + cpu + "%")
        print("  Memory: " + mem + "%")
```

### 场景 2：批量配置部署

```python
# 批量部署配置文件
nodes = ["node1", "node2", "node3"]

# 创建配置
write_file("app.conf", "server_port=8080\nlog_level=info\n")

for node in nodes:
    conn = ssh_connect(node, "deploy")
    
    # 上传配置
    ssh_copy(conn, "app.conf", "/etc/app/app.conf")
    
    # 重启服务
    ssh_exec(conn, "sudo systemctl restart app")
    
    print(node + " 部署完成")
```

### 场景 3：跨系统数据同步

```python
# 主服务器
master = ssh_connect("master.example.com", "admin")

# 备份服务器
backup = ssh_connect("backup.example.com", "admin")

# 从主服务器下载数据
ssh_download(master, "/data/important.db", "important.db")

# 上传到备份服务器
ssh_copy(backup, "important.db", "/backup/important.db")

print("数据同步完成")
```

### 场景 4：多发行版统一管理

```python
# 管理不同发行版的服务器
ubuntu_server = ssh_connect("ubuntu.local", "admin")
fedora_server = ssh_connect("fedora.local", "admin")
arch_server = ssh_connect("arch.local", "admin")

# 在所有服务器上安装 nginx（自动适配包管理器）
servers = [ubuntu_server, fedora_server, arch_server]

for server in servers:
    distro = remote_distro(server)
    print("在 " + distro + " 上安装 nginx...")
    
    success = remote_pkg_install(server, "nginx")
    
    if success:
        print("  ✓ 安装成功")
    else:
        print("  ✗ 安装失败")
```

## SSH 密钥配置

为了安全和便捷地使用多系统互联功能，建议配置 SSH 密钥认证：

### 1. 生成 SSH 密钥对

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

### 2. 复制公钥到远程服务器

```bash
ssh-copy-id user@remote-host
```

### 3. 测试连接

```bash
ssh user@remote-host
```

### 4. 配置 SSH 配置文件（可选）

编辑 `~/.ssh/config`：

```
Host server1
    HostName 192.168.1.100
    User admin
    IdentityFile ~/.ssh/id_rsa

Host server2
    HostName 192.168.1.101
    User admin
    IdentityFile ~/.ssh/id_rsa
```

然后在 PC 语言中可以直接使用别名：

```python
conn = ssh_connect("server1", "admin")
```

## 安全注意事项

1. **使用密钥认证**：避免使用密码认证，使用 SSH 密钥更安全
2. **限制权限**：为自动化脚本创建专用用户，限制 sudo 权限
3. **防火墙配置**：确保只允许必要的 IP 访问 SSH 端口
4. **日志审计**：定期检查 SSH 登录日志（`/var/log/auth.log`）
5. **密钥管理**：定期轮换 SSH 密钥，保护私钥安全

## 故障排查

### 连接失败

```python
conn = ssh_connect("server1", "admin")

if not conn:
    print("连接失败，请检查：")
    print("1. SSH 服务是否运行: systemctl status sshd")
    print("2. 防火墙是否允许 SSH: sudo ufw status")
    print("3. 密钥认证是否配置: ssh -v user@host")
    print("4. 网络是否可达: ping server1")
```

### 命令执行失败

```python
result = ssh_exec(conn, "some-command")

if result == None:
    print("命令执行失败")
    # 尝试获取错误信息
    error = ssh_exec(conn, "some-command 2>&1")
    print("错误: " + error)
```

### 文件传输失败

```python
success = ssh_copy(conn, "file.txt", "/remote/path/file.txt")

if not success:
    print("文件传输失败，请检查：")
    print("1. 本地文件是否存在")
    print("2. 远程目录是否存在且有写权限")
    print("3. 磁盘空间是否充足")
```

## 性能优化

### 1. 复用连接

```python
# 一次连接，多次使用
conn = ssh_connect("server1", "admin")

# 执行多个命令
result1 = ssh_exec(conn, "command1")
result2 = ssh_exec(conn, "command2")
result3 = ssh_exec(conn, "command3")
```

### 2. 并行操作

```python
# 同时管理多个服务器
servers = ["server1", "server2", "server3"]
connections = []

# 建立所有连接
for server in servers:
    conn = ssh_connect(server, "admin")
    if conn:
        connections = append(connections, conn)

# 并行执行命令
for conn in connections:
    ssh_exec(conn, "update-command")
```

### 3. 使用 rsync 同步大文件

```python
# 对于大文件或目录，使用 sync_file 而不是 ssh_copy
# rsync 支持增量同步，更高效
sync_file(conn, "/local/bigdata/", "/remote/backup/")
```

## 示例程序

查看 `examples/` 目录中的完整示例：

- `multi_system_connect.pc` - 基础连接和操作示例
- `cluster_manager.pc` - 集群管理完整示例
- `multi_system_manager.pc` - 多系统协调管理

## 总结

PC 语言的多系统互联功能让你可以：

✅ 轻松连接和管理多个 Linux 系统  
✅ 跨发行版统一管理（Ubuntu/Debian/Fedora/Arch/Kali）  
✅ 批量执行命令和部署配置  
✅ 自动化系统监控和维护  
✅ 实现集群管理和协调  

开始使用 PC 语言构建你的多系统管理解决方案吧！
