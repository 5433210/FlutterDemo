#!/bin/bash

echo "=== 备份测试与监控脚本 ==="
echo "此脚本将帮助您测试备份功能并监控过程"
echo ""

# 检查是否在正确的目录
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 请在 Flutter 项目根目录运行此脚本"
    exit 1
fi

echo "🔧 准备环境..."

# 创建日志目录
mkdir -p logs

echo "📋 选择操作:"
echo "1) 运行备份诊断"
echo "2) 测试备份功能 (需要应用运行)"
echo "3) 监控备份日志"
echo "4) 查看最近的备份日志"

read -p "请选择 (1-4): " choice

case $choice in
    1)
        echo "🔍 运行备份诊断..."
        dart run scripts/diagnose_backup_simple.dart
        ;;
    2)
        echo "⚠️ 请确保应用正在运行，然后在应用中手动触发备份"
        echo "💡 建议同时打开另一个终端运行: bash scripts/test_backup.sh 选择3"
        echo ""
        read -p "准备就绪后按 Enter 继续监控..."
        dart run scripts/monitor_backup.dart
        ;;
    3)
        echo "📊 开始监控备份日志..."
        dart run scripts/monitor_backup.dart
        ;;
    4)
        echo "📄 最近的备份相关日志:"
        if [ -f "logs/app.log" ]; then
            grep -i "backup\|备份\|复制" logs/app.log | tail -20
        else
            echo "❌ 未找到日志文件"
        fi
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac
