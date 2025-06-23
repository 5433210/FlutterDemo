#!/bin/bash

echo "🔧 测试 Linux 文件对话框解决方案"
echo "================================="

# 1. 检查 zenity 是否安装
echo "1. 检查 zenity 安装状态..."
if command -v zenity &> /dev/null; then
    echo "✅ zenity 已安装: $(zenity --version)"
else
    echo "❌ zenity 未安装"
    exit 1
fi

# 2. 检查 Xvfb 是否可用
echo "2. 检查 Xvfb 安装状态..."
if command -v Xvfb &> /dev/null; then
    echo "✅ Xvfb 已安装"
else
    echo "❌ Xvfb 未安装"
    exit 1
fi

# 3. 启动虚拟显示器进行测试
echo "3. 测试虚拟显示器..."
Xvfb :98 -screen 0 800x600x24 &
TEST_XVFB_PID=$!
sleep 2

export DISPLAY=:98

# 4. 测试 zenity 对话框
echo "4. 测试文件对话框..."
if timeout 3s zenity --info --text="测试成功！文件对话框可以正常工作。" --timeout=2 2>/dev/null; then
    echo "✅ 文件对话框测试成功"
else
    echo "⚠️  文件对话框测试失败或超时"
fi

# 5. 清理测试环境
echo "5. 清理测试环境..."
kill $TEST_XVFB_PID 2>/dev/null
unset DISPLAY

echo ""
echo "🎉 测试完成！"
echo "💡 现在您可以使用 ./run_flutter_with_display.sh 来启动Flutter应用"
echo "🚀 或者使用VS Code任务: 'Flutter运行(支持文件对话框)'"
