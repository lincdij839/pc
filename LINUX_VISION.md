# PC 语言：Linux 系统互联专家

## 🎯 核心定位

**PC (Platform Connect) 语言** - 专为 Linux 系统互联设计的现代脚本语言

### 目标用户
- 🔐 渗透测试工程师 (Kali Linux)
- 🖥️ 系统管理员 (Ubuntu/Debian/Fedora/Arch)
- 🔧 DevOps 工程师
- 🐧 Linux 开发者
- 🛡️ 安全研究人员

---

## 🌟 核心特性

### 1. 包管理器统一接口
```python
# 自动检测发行版并使用对应的包管理器
pkg = package_manager()

# 统一的 API，适配所有发行版
pkg.install("nginx")           # apt/dnf/pacman 自动选择
pkg.remove("apache2")
pkg.update()
pkg.search("python")
pkg.list_installed()

# 发行版特定操作
if os_name() == "kali":
    pkg.install("metasploit-framework")
elif os_name() == "arch":
    pkg.install("yay")  # AUR helper
```

### 2. 系统服务管理
```python
# systemd 统一接口
service = systemd()

service.start("nginx")
service.stop("apache2")
service.restart("ssh")
service.enable("docker")
service.status("postgresql")

# 查看日志
logs = service.logs("nginx", lines=100)
print(logs)
```

### 3. 网络配置
```python
# 网络接口管理
net = network()

# 列出所有接口
interfaces = net.list_interfaces()

# 配置 IP
net.set_ip("eth0", "192.168.1.100", "255.255.255.0")

# 路由管理
net.add_route("10.0.0.0/8", "192.168.1.1")

# 防火墙 (iptables/nftables)
fw = firewall()
fw.allow("tcp", 80)
fw.block("192.168.1.50")
fw.list_rules()
```

### 4. 进程和系统监控
```python
# 进程管理
procs = process.list()
for p in procs:
    print(f"{p.pid}: {p.name} - {p.cpu}% CPU")

# 查找进程
nginx_procs = process.find("nginx")

# 杀死进程
process.kill(1234, signal="SIGTERM")

# 系统资源
sys = system()
print(f"CPU: {sys.cpu_percent()}%")
print(f"Memory: {sys.memory_percent()}%")
print(f"Disk: {sys.disk_usage('/')}%")
```

### 5. 文件系统操作
```python
# 高级文件操作
fs = filesystem()

# 查找文件
files = fs.find("/var/log", pattern="*.log", recursive=true)

# 监控文件变化
watcher = fs.watch("/etc")
watcher.on_change(lambda path: print(f"Changed: {path}"))

# 权限管理
fs.chmod("/tmp/script.sh", 0o755)
fs.chown("/var/www", "www-data", "www-data")

# 挂载管理
fs.mount("/dev/sdb1", "/mnt/data", "ext4")
fs.umount("/mnt/data")
```

### 6. 用户和权限管理
```python
# 用户管理
users = user_manager()

# 创建用户
users.create("alice", groups=["sudo", "docker"])

# 修改密码
users.set_password("alice", "newpassword")

# 检查权限
if users.has_sudo():
    print("Running with sudo privileges")

# 切换用户执行
users.run_as("www-data", "ls /var/www")
```

### 7. 安全工具集成 (Kali 专用)
```python
# Nmap 扫描
nmap = security.nmap()
results = nmap.scan("192.168.1.0/24", ports="1-1000")

# Metasploit 集成
msf = security.metasploit()
msf.use("exploit/multi/handler")
msf.set("PAYLOAD", "linux/x64/meterpreter/reverse_tcp")
msf.exploit()

# Wireshark/tcpdump
capture = security.packet_capture("eth0")
packets = capture.filter("tcp port 80")

# Hashcat/John
hash_crack = security.hash_cracker()
result = hash_crack.crack("5f4dcc3b5aa765d61d8327deb882cf99", type="md5")
```

### 8. 容器和虚拟化
```python
# Docker 管理
docker = container.docker()

# 容器操作
docker.run("nginx:latest", ports={"80": "8080"})
docker.stop("my-container")
docker.logs("my-container")

# 镜像管理
docker.pull("ubuntu:22.04")
docker.build(".", tag="myapp:v1")

# Docker Compose
compose = docker.compose("docker-compose.yml")
compose.up()
compose.down()
```

### 9. 配置文件解析
```python
# 自动解析各种配置格式
config = parse_config("/etc/nginx/nginx.conf")
config.set("worker_processes", 4)
config.save()

# 支持多种格式
yaml_config = parse_yaml("/etc/ansible/hosts.yml")
json_config = parse_json("/etc/config.json")
ini_config = parse_ini("/etc/app.ini")
```

### 10. Shell 命令增强
```python
# 管道和重定向
output = shell("ps aux | grep nginx | awk '{print $2}'")

# 命令链
shell("apt update && apt upgrade -y")

# 后台执行
job = shell.background("long-running-task")
job.wait()

# SSH 远程执行
ssh = remote("user@server.com")
result = ssh.exec("systemctl status nginx")
```

---

## 🏗️ 项目结构调整

### 新增模块
```
src/stdlib/
├── linux/
│   ├── package.zig       # 包管理器统一接口
│   ├── systemd.zig       # systemd 服务管理
│   ├── network.zig       # 网络配置
│   ├── firewall.zig      # 防火墙管理
│   ├── process.zig       # 进程管理
│   ├── filesystem.zig    # 文件系统操作
│   ├── users.zig         # 用户管理
│   ├── security.zig      # 安全工具 (Kali)
│   ├── container.zig     # 容器管理
│   └── config.zig        # 配置文件解析
├── sys_io.zig            # 系统 I/O (已有)
├── builtins.zig          # 内置函数
└── string_utils.zig      # 字符串工具
```

---

## 📦 发行版特定支持

### Kali Linux
```python
# 检测 Kali
if distro() == "kali":
    # Kali 专用工具
    tools = kali.tools()
    
    # 安装 Kali 工具
    tools.install("metasploit")
    tools.install("burpsuite")
    
    # 更新 Kali 工具
    tools.update_all()
```

### Debian/Ubuntu
```python
if distro() in ["debian", "ubuntu"]:
    # APT 包管理
    apt = package.apt()
    apt.update()
    apt.install("nginx")
    
    # PPA 管理 (Ubuntu)
    if distro() == "ubuntu":
        apt.add_ppa("ppa:deadsnakes/ppa")
```

### Fedora
```python
if distro() == "fedora":
    # DNF 包管理
    dnf = package.dnf()
    dnf.install("nginx")
    
    # SELinux 管理
    selinux = security.selinux()
    selinux.set_mode("enforcing")
```

### Arch Linux
```python
if distro() == "arch":
    # Pacman 包管理
    pacman = package.pacman()
    pacman.install("nginx")
    
    # AUR 支持
    aur = package.aur()
    aur.install("yay")
```

---

## 🚀 实际应用场景

### 场景 1: 自动化服务器配置
```python
#!/usr/bin/env pc

# 检测系统
print(f"Configuring {distro()} {distro_version()}")

# 更新系统
pkg = package_manager()
pkg.update()
pkg.upgrade()

# 安装必要软件
packages = ["nginx", "postgresql", "redis", "docker"]
for p in packages:
    print(f"Installing {p}...")
    pkg.install(p)

# 配置防火墙
fw = firewall()
fw.allow("tcp", 80)
fw.allow("tcp", 443)
fw.allow("tcp", 22)

# 启动服务
service = systemd()
service.enable("nginx")
service.enable("postgresql")
service.start("nginx")
service.start("postgresql")

print("Server configured successfully!")
```

### 场景 2: 网络扫描和监控 (Kali)
```python
#!/usr/bin/env pc

# 网络发现
nmap = security.nmap()
print("Scanning network...")
hosts = nmap.scan("192.168.1.0/24", args="-sn")

print(f"Found {len(hosts)} hosts:")
for host in hosts:
    print(f"  {host.ip} - {host.hostname}")

# 端口扫描
for host in hosts:
    print(f"\nScanning {host.ip}...")
    ports = nmap.scan(host.ip, ports="1-1000")
    
    for port in ports.open:
        print(f"  Port {port.number}: {port.service}")
```

### 场景 3: 日志分析
```python
#!/usr/bin/env pc

# 分析 Nginx 访问日志
log_file = "/var/log/nginx/access.log"

# 统计 IP 访问次数
ip_counts = {}
for line in read_file(log_file).split("\n"):
    if line:
        ip = line.split()[0]
        ip_counts[ip] = ip_counts.get(ip, 0) + 1

# 排序并显示 Top 10
sorted_ips = sorted(ip_counts.items(), key=lambda x: x[1], reverse=true)
print("Top 10 访问 IP:")
for ip, count in sorted_ips[:10]:
    print(f"{ip}: {count} 次")
```

### 场景 4: 容器部署
```python
#!/usr/bin/env pc

# Docker 部署脚本
docker = container.docker()

# 拉取镜像
print("Pulling images...")
docker.pull("nginx:latest")
docker.pull("postgres:14")
docker.pull("redis:7")

# 创建网络
docker.network_create("myapp-network")

# 启动数据库
docker.run("postgres:14",
    name="db",
    network="myapp-network",
    env={
        "POSTGRES_PASSWORD": "secret",
        "POSTGRES_DB": "myapp"
    },
    volumes={"/var/lib/postgresql/data": "/data/postgres"}
)

# 启动 Redis
docker.run("redis:7",
    name="cache",
    network="myapp-network"
)

# 启动应用
docker.run("myapp:latest",
    name="app",
    network="myapp-network",
    ports={"80": "8080"},
    depends_on=["db", "cache"]
)

print("Application deployed!")
```

### 场景 5: 系统监控
```python
#!/usr/bin/env pc

# 系统监控脚本
def monitor():
    sys = system()
    
    # CPU 使用率
    cpu = sys.cpu_percent()
    if cpu > 80:
        print(f"⚠️  High CPU usage: {cpu}%")
    
    # 内存使用率
    mem = sys.memory_percent()
    if mem > 90:
        print(f"⚠️  High memory usage: {mem}%")
    
    # 磁盘使用率
    disk = sys.disk_usage("/")
    if disk > 85:
        print(f"⚠️  High disk usage: {disk}%")
    
    # 检查关键服务
    service = systemd()
    critical_services = ["nginx", "postgresql", "docker"]
    
    for svc in critical_services:
        status = service.status(svc)
        if status != "active":
            print(f"❌ Service {svc} is {status}")

# 每 60 秒监控一次
while true:
    monitor()
    sleep(60)
```

---

## 🔧 安装和配置

### 系统要求
- Linux 发行版: Kali/Debian/Ubuntu/Fedora/Arch
- Zig 0.13.0+
- 可选: Docker, systemd

### 安装脚本
```bash
#!/bin/bash
# install.sh - PC 语言安装脚本

# 检测发行版
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "无法检测发行版"
    exit 1
fi

echo "检测到发行版: $DISTRO"

# 安装依赖
case $DISTRO in
    kali|debian|ubuntu)
        sudo apt update
        sudo apt install -y build-essential curl git
        ;;
    fedora)
        sudo dnf install -y gcc make curl git
        ;;
    arch)
        sudo pacman -Sy --noconfirm base-devel curl git
        ;;
esac

# 安装 Zig
if ! command -v zig &> /dev/null; then
    echo "安装 Zig..."
    curl -L https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz | tar -xJ
    sudo mv zig-linux-x86_64-0.13.0 /opt/zig
    sudo ln -sf /opt/zig/zig /usr/local/bin/zig
fi

# 编译 PC 语言
echo "编译 PC 语言..."
zig build -Doptimize=ReleaseFast

# 安装到系统
sudo cp zig-out/bin/pc /usr/local/bin/
sudo chmod +x /usr/local/bin/pc

echo "✅ PC 语言安装完成！"
echo "运行 'pc --version' 测试安装"
```

---

## 📚 文档结构

```
docs/
├── getting-started.md
├── linux/
│   ├── package-management.md
│   ├── systemd.md
│   ├── networking.md
│   ├── security.md
│   └── containers.md
├── distros/
│   ├── kali.md
│   ├── debian.md
│   ├── ubuntu.md
│   ├── fedora.md
│   └── arch.md
├── examples/
│   ├── server-setup.pc
│   ├── network-scan.pc
│   ├── log-analysis.pc
│   └── monitoring.pc
└── api/
    └── stdlib-reference.md
```

---

## 🎯 开发优先级

### 第 1 周: 核心系统互联
- [ ] 包管理器统一接口
- [ ] systemd 服务管理
- [ ] 进程管理增强
- [ ] 文件系统操作

### 第 2 周: 网络和安全
- [ ] 网络配置 API
- [ ] 防火墙管理
- [ ] SSH 远程执行
- [ ] 基础安全工具

### 第 3 周: 容器和配置
- [ ] Docker 集成
- [ ] 配置文件解析
- [ ] 用户管理
- [ ] Shell 命令增强

### 第 4 周: 发行版适配
- [ ] Kali 工具集成
- [ ] 各发行版测试
- [ ] 文档完善
- [ ] 示例程序

---

**PC 语言 - Linux 系统互联的最佳选择！** 🐧
