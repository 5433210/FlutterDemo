#!/bin/bash

# WSL中构建Flutter Linux版本的快速脚本

set -e

echo "🐧 在WSL中构建Flutter Linux版本..."

# 检查是否在WSL环境中
if ! grep -q Microsoft /proc/version; then
    echo "❌ 错误: 此脚本需要在WSL环境中运行"
    echo "请使用以下命令进入WSL:"
    echo "wsl -d Arch"
    exit 1
fi

# 检查Flutter是否安装
if ! command -v flutter &> /dev/null; then
    echo "❌ 错误: Flutter未安装"
    echo "请先运行设置脚本: ./scripts/setup_wsl_flutter.sh"
    exit 1
fi

# 确保在项目目录
PROJECT_DIR="/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 错误: 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"
echo "📁 切换到项目目录: $(pwd)"

# 检查pubspec.yaml
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 错误: 未找到pubspec.yaml文件"
    exit 1
fi

# 启用Linux桌面支持
echo "🔧 启用Linux桌面支持..."
flutter config --enable-linux-desktop

# 获取依赖
echo "📦 获取Flutter依赖..."
flutter pub get

# 生成本地化文件
echo "🌍 生成本地化文件..."
flutter gen-l10n

# 清理之前的构建
echo "🧹 清理之前的构建..."
flutter clean
flutter pub get

# 构建Linux版本
echo "🔨 构建Linux版本..."
flutter build linux --release

# 检查构建结果
BUILD_DIR="build/linux/x64/release/bundle"
if [ -d "$BUILD_DIR" ]; then
    echo "✅ Linux构建成功！"
    echo "📁 构建产物位置: $BUILD_DIR"
    echo "📊 构建大小:"
    du -sh "$BUILD_DIR"
    echo ""
    echo "📋 构建内容:"
    ls -la "$BUILD_DIR"
    echo ""
    echo "🎉 可以在Windows中运行以下命令来测试："
    echo "wsl -d Arch -e $BUILD_DIR/demo"
else
    echo "❌ 构建失败！未找到构建产物"
    exit 1
fi

echo ""
echo "💡 提示："
echo "- 构建的Linux应用可以在WSL中运行"
echo "- 如果需要图形界面，确保WSL支持图形显示"
echo "- 可以将构建产物复制到真正的Linux系统中运行" 