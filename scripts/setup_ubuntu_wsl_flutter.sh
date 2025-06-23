#!/bin/bash

# Ubuntu WSL Flutter Linux构建环境设置脚本

set -e

echo "🐧 开始设置Ubuntu WSL Flutter Linux构建环境..."

# 检查是否在WSL环境中
if ! grep -q -i "microsoft\|wsl" /proc/version 2>/dev/null; then
    echo "❌ 错误: 此脚本需要在WSL环境中运行"
    echo "当前环境: $(uname -a)"
    exit 1
fi

echo "✅ 检测到WSL环境"

# 更新系统包
echo "📦 更新系统包..."
sudo apt update
sudo apt upgrade -y

# 安装Flutter Linux构建所需的依赖
echo "🔧 安装Flutter Linux构建依赖..."
sudo apt install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    libblkid-dev \
    liblzma-dev \
    clang

# 检查Flutter是否已安装
if ! command -v flutter &> /dev/null; then
    echo "📱 Flutter未安装，正在下载安装..."
    
    # 创建flutter目录
    mkdir -p ~/development
    cd ~/development
    
    # 下载Flutter Linux版本
    echo "📥 下载Flutter SDK..."
    wget -O flutter_linux.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
    
    # 解压Flutter
    echo "📂 解压Flutter SDK..."
    tar xf flutter_linux.tar.xz
    
    # 添加Flutter到PATH
    echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
    export PATH="$PATH:$HOME/development/flutter/bin"
    
    # 清理下载文件
    rm flutter_linux.tar.xz
    
    echo "✅ Flutter安装完成"
else
    echo "✅ Flutter已安装"
fi

# 验证Flutter安装
echo "🔍 验证Flutter安装..."
flutter --version

# 启用Linux桌面支持
echo "🐧 启用Linux桌面支持..."
flutter config --enable-linux-desktop

# 运行Flutter doctor检查Linux构建支持
echo "🩺 运行Flutter doctor检查..."
flutter doctor

# 检查并安装Chrome（用于Web开发，可选）
if ! command -v google-chrome &> /dev/null; then
    echo "🌐 安装Google Chrome（用于Web开发）..."
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
    sudo apt update
    sudo apt install -y google-chrome-stable
fi

echo ""
echo "🎉 Ubuntu WSL Flutter Linux构建环境设置完成！"
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
echo "- Ubuntu WSL支持图形界面，可以直接运行GUI应用"
echo "- 如果遇到图形界面问题，确保Windows 11或安装了X11服务器" 