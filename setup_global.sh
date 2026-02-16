#!/bin/bash
# PC Language 全局环境配置脚本

echo "========================================"
echo "PC Language 全局环境配置"
echo "========================================"
echo ""

# 获取当前目录
CURRENT_DIR=$(pwd)
PC_BIN="$CURRENT_DIR/zig-out/bin/pc"

# 检查 pc 可执行文件是否存在
if [ ! -f "$PC_BIN" ]; then
    echo "❌ 错误: 找不到 $PC_BIN"
    echo "请先运行: zig build"
    exit 1
fi

echo "✓ 找到 PC 可执行文件: $PC_BIN"
echo ""

# 1. 创建智能包装脚本
echo "1️⃣  创建智能包装脚本..."

cat > /tmp/pc << EOF
#!/bin/bash
# PC Language 智能包装脚本

PC_BIN="$PC_BIN"
PC_SCRIPTS="\$HOME/.pc_scripts"

# 如果没有参数，显示帮助
if [ -z "\$1" ]; then
    echo "PC Language - 多系统管理工具"
    echo ""
    echo "用法: pc <命令> [系统]"
    echo ""
    echo "常用命令:"
    echo "  pc info                    - 查看所有系统信息"
    echo "  pc update                  - 更新所有系统"
    echo "  pc update kali             - 更新 Kali 系统"
    echo "  pc monitor                 - 监控集群状态"
    echo "  pc backup                  - 备份系统配置"
    echo ""
    echo "软件包管理:"
    echo "  pc kali install nmap       - 在 Kali 上安装 nmap"
    echo "  pc debian install vim      - 在 Debian 上安装 vim"
    echo "  pc all install htop        - 在所有系统上安装 htop"
    echo "  pc kali remove nmap        - 在 Kali 上卸载 nmap"
    echo ""
    echo "执行命令:"
    echo "  pc kali ls -la             - 在 Kali 上执行 ls -la"
    echo "  pc debian cat /etc/hosts   - 在 Debian 上查看 hosts"
    echo "  pc arch uname -a           - 在 Arch 上查看内核信息"
    echo "  pc all whoami              - 在所有系统上执行 whoami"
    echo ""
    echo "其他命令:"
    echo "  pc hostname kali           - 查看 Kali 主机名"
    echo ""
    echo "可用系统: ubuntu, debian, fedora, arch, kali, opensuse, rocky, all"
    echo ""
    echo "或直接运行脚本:"
    echo "  pc <脚本文件.pc>"
    exit 0
fi

CMD="\$1"
SYSTEM="\${2:-all}"
ACTION="\${3}"

# 如果第二个参数是 install/remove，说明格式是: pc <系统> install <包>
if [ "\$SYSTEM" == "install" ] || [ "\$SYSTEM" == "remove" ] || [ "\$SYSTEM" == "uninstall" ]; then
    ACTION="\$SYSTEM"
    SYSTEM="all"
    PACKAGE="\$3"
elif [ "\$ACTION" == "install" ] || [ "\$ACTION" == "remove" ] || [ "\$ACTION" == "uninstall" ]; then
    # 格式是: pc <系统> install <包>
    PACKAGE="\${4}"
else
    PACKAGE=""
fi

# 如果是 .pc 文件，直接运行
if [[ "\$CMD" == *.pc ]]; then
    if [ -f "\$CMD" ]; then
        \$PC_BIN "\$CMD"
    elif [ -f "\$PC_SCRIPTS/\$CMD" ]; then
        \$PC_BIN "\$PC_SCRIPTS/\$CMD"
    else
        echo "❌ 找不到文件: \$CMD"
        exit 1
    fi
    exit 0
fi

# 命令映射
case "\$CMD" in
    # 系统名称作为第一个参数的情况
    ubuntu|debian|fedora|arch|kali|opensuse|rocky|all)
        SYSTEM="\$CMD"
        CMD="\$2"
        
        case "\$CMD" in
            install)
                PACKAGE="\$3"
                if [ -z "\$PACKAGE" ]; then
                    echo "❌ 错误: 未指定软件包名称"
                    echo "用法: pc <系统> install <软件包>"
                    echo "示例: pc kali install nmap"
                    exit 1
                fi
                
                echo "📦 在 \$SYSTEM 上安装 \$PACKAGE..."
                echo ""
                
                case "\$SYSTEM" in
                    ubuntu)
                        sudo apt install -y "\$PACKAGE"
                        ;;
                    debian)
                        lxc exec my-debian -- apt install -y "\$PACKAGE"
                        ;;
                    fedora)
                        lxc exec my-fedora -- dnf install -y "\$PACKAGE"
                        ;;
                    arch)
                        lxc exec my-arch -- pacman -S --noconfirm "\$PACKAGE"
                        ;;
                    kali)
                        lxc exec my-kali -- apt install -y "\$PACKAGE"
                        ;;
                    opensuse)
                        lxc exec my-opensuse -- zypper install -y "\$PACKAGE"
                        ;;
                    rocky)
                        lxc exec my-rocky -- dnf install -y "\$PACKAGE"
                        ;;
                    all)
                        echo "1️⃣  Ubuntu:"
                        sudo apt install -y "\$PACKAGE"
                        echo ""
                        echo "2️⃣  Debian:"
                        lxc exec my-debian -- apt install -y "\$PACKAGE"
                        echo ""
                        echo "3️⃣  Fedora:"
                        lxc exec my-fedora -- dnf install -y "\$PACKAGE"
                        echo ""
                        echo "4️⃣  Arch:"
                        lxc exec my-arch -- pacman -S --noconfirm "\$PACKAGE"
                        echo ""
                        echo "5️⃣  Kali:"
                        lxc exec my-kali -- apt install -y "\$PACKAGE"
                        echo ""
                        echo "6️⃣  openSUSE:"
                        lxc exec my-opensuse -- zypper install -y "\$PACKAGE"
                        echo ""
                        echo "7️⃣  Rocky Linux:"
                        lxc exec my-rocky -- dnf install -y "\$PACKAGE"
                        ;;
                esac
                
                echo ""
                echo "✅ 安装完成"
                ;;
            
            remove|uninstall)
                PACKAGE="\$3"
                if [ -z "\$PACKAGE" ]; then
                    echo "❌ 错误: 未指定软件包名称"
                    echo "用法: pc <系统> remove <软件包>"
                    exit 1
                fi
                
                echo "🗑️  在 \$SYSTEM 上卸载 \$PACKAGE..."
                echo ""
                
                case "\$SYSTEM" in
                    ubuntu)
                        sudo apt remove -y "\$PACKAGE"
                        ;;
                    debian)
                        lxc exec my-debian -- apt remove -y "\$PACKAGE"
                        ;;
                    fedora)
                        lxc exec my-fedora -- dnf remove -y "\$PACKAGE"
                        ;;
                    arch)
                        lxc exec my-arch -- pacman -R --noconfirm "\$PACKAGE"
                        ;;
                    kali)
                        lxc exec my-kali -- apt remove -y "\$PACKAGE"
                        ;;
                    opensuse)
                        lxc exec my-opensuse -- zypper remove -y "\$PACKAGE"
                        ;;
                    rocky)
                        lxc exec my-rocky -- dnf remove -y "\$PACKAGE"
                        ;;
                esac
                
                echo ""
                echo "✅ 卸载完成"
                ;;
            
            update)
                echo "🔄 更新 \$SYSTEM..."
                echo ""
                
                case "\$SYSTEM" in
                    ubuntu)
                        sudo apt update
                        ;;
                    debian)
                        lxc exec my-debian -- apt update
                        ;;
                    fedora)
                        lxc exec my-fedora -- dnf check-update
                        ;;
                    arch)
                        lxc exec my-arch -- pacman -Sy
                        ;;
                    kali)
                        lxc exec my-kali -- apt update
                        ;;
                    opensuse)
                        lxc exec my-opensuse -- zypper refresh
                        ;;
                    rocky)
                        lxc exec my-rocky -- dnf check-update
                        ;;
                    all)
                        echo "1️⃣  Ubuntu:"
                        sudo apt update
                        echo ""
                        echo "2️⃣  Debian:"
                        lxc exec my-debian -- apt update
                        echo ""
                        echo "3️⃣  Fedora:"
                        lxc exec my-fedora -- dnf check-update
                        echo ""
                        echo "4️⃣  Arch:"
                        lxc exec my-arch -- pacman -Sy
                        echo ""
                        echo "5️⃣  Kali:"
                        lxc exec my-kali -- apt update
                        echo ""
                        echo "6️⃣  openSUSE:"
                        lxc exec my-opensuse -- zypper refresh
                        echo ""
                        echo "7️⃣  Rocky Linux:"
                        lxc exec my-rocky -- dnf check-update
                        ;;
                esac
                
                echo ""
                echo "✅ 更新完成"
                ;;
            
            *)
                # 通用命令执行: pc <系统> <任意命令>
                COMMAND="\${@:2}"
                if [ -z "\$COMMAND" ]; then
                    echo "❌ 错误: 未指定命令"
                    echo "用法: pc <系统> <命令>"
                    echo "示例: pc kali ls -la"
                    echo "      pc debian cat /etc/os-release"
                    exit 1
                fi
                
                echo "⚡ 在 \$SYSTEM 上执行: \$COMMAND"
                echo ""
                
                case "\$SYSTEM" in
                    ubuntu)
                        sh -c "\$COMMAND"
                        ;;
                    debian)
                        lxc exec my-debian -- sh -c "\$COMMAND"
                        ;;
                    fedora)
                        lxc exec my-fedora -- sh -c "\$COMMAND"
                        ;;
                    arch)
                        lxc exec my-arch -- sh -c "\$COMMAND"
                        ;;
                    kali)
                        lxc exec my-kali -- sh -c "\$COMMAND"
                        ;;
                    opensuse)
                        lxc exec my-opensuse -- sh -c "\$COMMAND"
                        ;;
                    rocky)
                        lxc exec my-rocky -- sh -c "\$COMMAND"
                        ;;
                    all)
                        echo "1️⃣  Ubuntu:"
                        sh -c "\$COMMAND"
                        echo ""
                        echo "2️⃣  Debian:"
                        lxc exec my-debian -- sh -c "\$COMMAND"
                        echo ""
                        echo "3️⃣  Fedora:"
                        lxc exec my-fedora -- sh -c "\$COMMAND"
                        echo ""
                        echo "4️⃣  Arch:"
                        lxc exec my-arch -- sh -c "\$COMMAND"
                        echo ""
                        echo "5️⃣  Kali:"
                        lxc exec my-kali -- sh -c "\$COMMAND"
                        echo ""
                        echo "6️⃣  openSUSE:"
                        lxc exec my-opensuse -- sh -c "\$COMMAND"
                        echo ""
                        echo "7️⃣  Rocky Linux:"
                        lxc exec my-rocky -- sh -c "\$COMMAND"
                        ;;
                esac
                ;;
        esac
        ;;
    
    # 通用命令执行: pc exec <系统> <命令>
    exec|run)
        SYSTEM="\$2"
        COMMAND="\${@:3}"
        
        if [ -z "\$SYSTEM" ] || [ -z "\$COMMAND" ]; then
            echo "❌ 错误: 参数不完整"
            echo "用法: pc exec <系统> <命令>"
            echo "示例: pc exec kali nmap -sV localhost"
            exit 1
        fi
        
        echo "⚡ 在 \$SYSTEM 上执行: \$COMMAND"
        echo ""
        
        case "\$SYSTEM" in
            ubuntu)
                sh -c "\$COMMAND"
                ;;
            debian)
                lxc exec my-debian -- sh -c "\$COMMAND"
                ;;
            fedora)
                lxc exec my-fedora -- sh -c "\$COMMAND"
                ;;
            arch)
                lxc exec my-arch -- sh -c "\$COMMAND"
                ;;
            kali)
                lxc exec my-kali -- sh -c "\$COMMAND"
                ;;
            opensuse)
                lxc exec my-opensuse -- sh -c "\$COMMAND"
                ;;
            rocky)
                lxc exec my-rocky -- sh -c "\$COMMAND"
                ;;
            all)
                echo "1️⃣  Ubuntu:"
                sh -c "\$COMMAND"
                echo ""
                echo "2️⃣  Debian:"
                lxc exec my-debian -- sh -c "\$COMMAND"
                echo ""
                echo "3️⃣  Fedora:"
                lxc exec my-fedora -- sh -c "\$COMMAND"
                echo ""
                echo "4️⃣  Arch:"
                lxc exec my-arch -- sh -c "\$COMMAND"
                echo ""
                echo "5️⃣  Kali:"
                lxc exec my-kali -- sh -c "\$COMMAND"
                echo ""
                echo "6️⃣  openSUSE:"
                lxc exec my-opensuse -- sh -c "\$COMMAND"
                echo ""
                echo "7️⃣  Rocky Linux:"
                lxc exec my-rocky -- sh -c "\$COMMAND"
                ;;
            *)
                echo "❌ 未知系统: \$SYSTEM"
                exit 1
                ;;
        esac
        ;;
    
    info)
        \$PC_BIN "\$PC_SCRIPTS/multi_system.pc"
        ;;
    
    update)
        echo "🔄 更新所有系统..."
        echo ""
        echo "1️⃣  Ubuntu:"
        sudo apt update
        echo ""
        echo "2️⃣  Debian:"
        lxc exec my-debian -- apt update
        echo ""
        echo "3️⃣  Fedora:"
        lxc exec my-fedora -- dnf check-update
        echo ""
        echo "4️⃣  Arch:"
        lxc exec my-arch -- pacman -Sy
        echo ""
        echo "5️⃣  Kali:"
        sudo apt update
        echo ""
        echo "6️⃣  openSUSE:"
        lxc exec my-opensuse -- zypper refresh
        echo ""
        echo "7️⃣  Rocky Linux:"
        lxc exec my-rocky -- dnf check-update
        echo ""
        echo "✅ 更新完成"
        ;;
    
    install)
        PACKAGE="\$2"
        if [ -z "\$PACKAGE" ]; then
            echo "❌ 错误: 未指定软件包名称"
            echo "用法: pc install <软件包>  (在所有系统上安装)"
            echo "或:   pc <系统> install <软件包>"
            exit 1
        fi
        
        echo "📦 在所有系统上安装 \$PACKAGE..."
        echo ""
        echo "1️⃣  Ubuntu:"
        sudo apt install -y "\$PACKAGE"
        echo ""
        echo "2️⃣  Debian:"
        lxc exec my-debian -- apt install -y "\$PACKAGE"
        echo ""
        echo "3️⃣  Fedora:"
        lxc exec my-fedora -- dnf install -y "\$PACKAGE"
        echo ""
        echo "4️⃣  Arch:"
        lxc exec my-arch -- pacman -S --noconfirm "\$PACKAGE"
        echo ""
        echo "5️⃣  Kali:"
        lxc exec my-kali -- apt install -y "\$PACKAGE"
        echo ""
        echo "6️⃣  openSUSE:"
        lxc exec my-opensuse -- zypper install -y "\$PACKAGE"
        echo ""
        echo "7️⃣  Rocky Linux:"
        lxc exec my-rocky -- dnf install -y "\$PACKAGE"
        echo ""
        echo "✅ 安装完成"
        ;;
    
    hostname)
        SYSTEM="\$2"
        if [ -z "\$SYSTEM" ]; then
            echo "❌ 错误: 未指定系统"
            echo "用法: pc hostname <系统>"
            exit 1
        fi
        
        case "\$SYSTEM" in
            ubuntu)
                hostname
                ;;
            debian)
                lxc exec my-debian -- hostname
                ;;
            fedora)
                lxc exec my-fedora -- hostname
                ;;
            arch)
                lxc exec my-arch -- hostname
                ;;
            kali)
                lxc exec my-kali -- hostname
                ;;
            opensuse)
                lxc exec my-opensuse -- hostname
                ;;
            rocky)
                lxc exec my-rocky -- hostname
                ;;
            all)
                echo "Ubuntu: \$(hostname)"
                echo "Debian: \$(lxc exec my-debian -- hostname)"
                echo "Fedora: \$(lxc exec my-fedora -- hostname)"
                echo "Arch: \$(lxc exec my-arch -- hostname)"
                echo "Kali: \$(lxc exec my-kali -- hostname)"
                echo "openSUSE: \$(lxc exec my-opensuse -- hostname)"
                echo "Rocky: \$(lxc exec my-rocky -- hostname)"
                ;;
            *)
                echo "❌ 未知系统: \$SYSTEM"
                exit 1
                ;;
        esac
        ;;
    
    monitor)
        \$PC_BIN "\$PC_SCRIPTS/monitor_cluster.pc"
        ;;
    
    backup)
        \$PC_BIN "\$PC_SCRIPTS/backup_system.pc"
        ;;
    
    sync)
        \$PC_BIN "\$PC_SCRIPTS/sync_config.pc"
        ;;
    
    list)
        echo "可用脚本:"
        ls -1 "\$PC_SCRIPTS"/*.pc | xargs -n1 basename
        ;;
    
    *)
        # 尝试直接查找脚本
        SCRIPT="\$PC_SCRIPTS/\${CMD}.pc"
        if [ -f "\$SCRIPT" ]; then
            \$PC_BIN "\$SCRIPT"
        else
            echo "❌ 未知命令: \$CMD"
            echo ""
            echo "运行 'pc' 查看帮助"
            exit 1
        fi
        ;;
esac
EOF

sudo mv /tmp/pc /usr/local/bin/pc
sudo chmod +x /usr/local/bin/pc
echo "   ✓ 已创建智能包装脚本: /usr/local/bin/pc"
echo ""

# 2. 创建脚本目录
echo "2️⃣  配置脚本目录..."

PC_SCRIPTS_DIR="$HOME/.pc_scripts"
if [ ! -d "$PC_SCRIPTS_DIR" ]; then
    mkdir -p "$PC_SCRIPTS_DIR"
    echo "   ✓ 已创建: $PC_SCRIPTS_DIR"
else
    echo "   ✓ 目录已存在: $PC_SCRIPTS_DIR"
fi

# 复制所有 .pc 文件到脚本目录
cp *.pc "$PC_SCRIPTS_DIR/" 2>/dev/null
echo "   ✓ 已复制所有脚本到 $PC_SCRIPTS_DIR"
echo ""

# 4. 配置环境变量
echo "3️⃣  配置环境变量..."

BASHRC="$HOME/.bashrc"

# 检查是否已经配置
if grep -q "PC_SCRIPTS_DIR" "$BASHRC"; then
    echo "   ✓ 环境变量已配置"
else
    echo "" >> "$BASHRC"
    echo "# PC Language 配置" >> "$BASHRC"
    echo "export PC_SCRIPTS_DIR=\"$PC_SCRIPTS_DIR\"" >> "$BASHRC"
    echo "export PATH=\"\$PC_SCRIPTS_DIR:\$PATH\"" >> "$BASHRC"
    echo "   ✓ 已添加到 $BASHRC"
fi
echo ""

# 完成
echo "========================================"
echo "✅ 全局环境配置完成！"
echo "========================================"
echo ""
echo "📋 使用方法："
echo ""
echo "1. 重新加载配置:"
echo "   source ~/.bashrc"
echo ""
echo "2. 使用 pc 命令:"
echo "   pc info                    # 查看所有系统"
echo "   pc update                  # 更新所有系统"
echo "   pc kali install nmap       # 安装软件"
echo "   pc arch ls -la             # 执行命令"
echo "   pc all whoami              # 在所有系统执行"
echo ""
