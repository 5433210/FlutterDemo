#!/bin/bash

# WSL Flutter Linux构建环境设置脚本
# 适用于Arch Linux WSL

set -e

echo "🐧 开始设置WSL Flutter Linux构建环境..."

# 检查是否在WSL环境中
if ! grep -q Microsoft /proc/version; then
    echo "❌ 错误: 此脚本需要在WSL环境中运行"
    exit 1
fi

echo "✅ 检测到WSL环境"

# 更新系统包
echo "📦 更新系统包..."
sudo pacman -Syu --noconfirm

# 安装Flutter Linux构建所需的依赖
echo "🔧 安装Flutter Linux构建依赖..."
sudo pacman -S --noconfirm \
    gtk3 \
    ninja \
    cmake \
    pkg-config \
    clang \
    curl \
    git \
    unzip \
    xz \
    zip \
    libgtk-3-dev \
    libblkid-dev \
    liblzma-dev

# 检查Flutter是否已安装
if ! command -v flutter &> /dev/null; then
    echo "📱 Flutter未安装，正在下载安装..."
    
    # 创建flutter目录
    mkdir -p ~/development
    cd ~/development
    
    # 下载Flutter Linux版本
    wget -O flutter_linux.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
    
    # 解压Flutter
    tar xf flutter_linux.tar.xz
    
    # 添加Flutter到PATH
    echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
    export PATH="$PATH:$HOME/development/flutter/bin"
    
    echo "✅ Flutter安装完成"
else
    echo "✅ Flutter已安装"
fi

# 验证Flutter安装
echo "🔍 验证Flutter安装..."
flutter --version

# 运行Flutter doctor检查Linux构建支持
echo "🩺 运行Flutter doctor检查..."
flutter doctor

# 检查Linux构建支持
echo "🐧 检查Linux构建支持..."
flutter config --enable-linux-desktop

echo ""
echo "🎉 WSL Flutter Linux构建环境设置完成！"
echo ""
echo "📋 使用说明："
echo "1. 在WSL中切换到项目目录："
echo "   cd /mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo"
echo ""
echo "2. 获取依赖："
echo "   flutter pub get"
echo ""
echo "3. 构建Linux版本："
echo "   flutter build linux"
echo ""
echo "4. 运行Linux版本："
echo "   flutter run -d linux"
echo ""
echo "💡 提示："
echo "- 构建产物将在 build/linux/x64/release/bundle/ 目录"
echo "- 如果遇到图形界面问题，可能需要安装X11转发或使用Windows的WSL图形支持" 