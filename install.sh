#!/bin/bash
# PC Language Installation Script for Linux
# 支持 Kali, Debian, Ubuntu, Fedora, Arch Linux

set -e

echo "=========================================="
echo "PC Language Installer"
echo "=========================================="
echo ""

# 检测发行版
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION=$VERSION_ID
else
    echo "❌ 无法检测 Linux 发行版"
    exit 1
fi

echo "✓ 检测到发行版: $DISTRO $VERSION"
echo ""

# 检查是否有 sudo 权限
if [ "$EUID" -ne 0 ]; then 
    if ! command -v sudo &> /dev/null; then
        echo "❌ 需要 sudo 权限，请以 root 用户运行或安装 sudo"
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# 安装依赖
echo "📦 安装依赖..."
case $DISTRO in
    kali|debian|ubuntu)
        $SUDO apt update
        $SUDO apt install -y build-essential curl git wget xz-utils
        ;;
    fedora|rhel|centos)
        $SUDO dnf install -y gcc make curl git wget xz
        ;;
    arch|manjaro)
        $SUDO pacman -Sy --noconfirm base-devel curl git wget xz
        ;;
    *)
        echo "⚠️  未知发行版: $DISTRO"
        echo "请手动安装: build-essential, curl, git, wget, xz-utils"
        ;;
esac

echo "✓ 依赖安装完成"
echo ""

# 检查 Zig 是否已安装
if command -v zig &> /dev/null; then
    ZIG_VERSION=$(zig version)
    echo "✓ Zig 已安装: $ZIG_VERSION"
else
    echo "📥 下载并安装 Zig 0.13.0..."
    
    # 检测架构
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        ZIG_ARCH="x86_64"
    elif [ "$ARCH" = "aarch64" ]; then
        ZIG_ARCH="aarch64"
    else
        echo "❌ 不支持的架构: $ARCH"
        exit 1
    fi
    
    # 下载 Zig
    ZIG_URL="https://ziglang.org/download/0.13.0/zig-linux-${ZIG_ARCH}-0.13.0.tar.xz"
    wget -q --show-progress "$ZIG_URL" -O /tmp/zig.tar.xz
    
    # 解压并安装
    $SUDO tar -xf /tmp/zig.tar.xz -C /opt/
    $SUDO ln -sf /opt/zig-linux-${ZIG_ARCH}-0.13.0/zig /usr/local/bin/zig
    
    # 清理
    rm /tmp/zig.tar.xz
    
    echo "✓ Zig 安装完成"
fi

echo ""

# 编译 PC 语言
echo "🔨 编译 PC 语言..."
zig build -Doptimize=ReleaseFast

echo "✓ 编译完成"
echo ""

# 安装到系统
echo "📦 安装 PC 语言到系统..."
$SUDO cp zig-out/bin/pc /usr/local/bin/
$SUDO chmod +x /usr/local/bin/pc

echo "✓ 安装完成"
echo ""

# 验证安装
echo "🧪 验证安装..."
if command -v pc &> /dev/null; then
    echo "✓ PC 语言已成功安装"
    echo ""
    echo "运行示例:"
    echo "  pc examples/hello.pc"
    echo "  pc examples/linux_system_info.pc"
    echo ""
else
    echo "❌ 安装失败"
    exit 1
fi

echo "=========================================="
echo "✅ 安装完成！"
echo "=========================================="
echo ""
echo "快速开始:"
echo "  1. 查看示例: ls examples/"
echo "  2. 运行程序: pc your_script.pc"
echo "  3. 查看文档: cat README.md"
echo ""
echo "系统互联功能:"
echo "  - 包管理: pkg_install(), pkg_search()"
echo "  - 服务管理: service_start(), service_status()"
echo "  - 系统信息: distro(), os_name(), arch()"
echo ""
