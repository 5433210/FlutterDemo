#!/bin/bash

echo "🐧 Flutter Linux WSL 构建脚本"

# Flutter路径
FLUTTER_BIN="/home/wailik/development/flutter/bin/flutter"

# 检查Flutter是否存在
if [ ! -f "$FLUTTER_BIN" ]; then
    echo "❌ Flutter未找到，请先运行安装脚本"
    exit 1
fi

# 检查项目目录
PROJECT_DIR="/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录未找到: $PROJECT_DIR"
    exit 1
fi

echo "🔍 切换到项目目录..."
cd "$PROJECT_DIR"

echo "🧹 清理构建缓存..."
$FLUTTER_BIN clean

echo "📦 获取依赖..."
$FLUTTER_BIN pub get

echo "🔨 构建Linux版本..."
$FLUTTER_BIN build linux --release

echo "✅ 构建完成！"
echo "📁 构建文件位置: build/linux/x64/release/bundle/"

# 显示构建输出大小
if [ -d "build/linux/x64/release/bundle" ]; then
    echo "📊 构建大小:"
    du -sh build/linux/x64/release/bundle
fi 