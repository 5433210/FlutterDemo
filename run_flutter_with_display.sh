#!/bin/bash

# 启动 Flutter 应用并支持文件对话框
# 这个脚本解决了在 headless 环境中运行 Flutter 应用时的文件选择器问题

echo "🚀 启动 Flutter 应用 (支持文件对话框)"

# 清理函数
cleanup() {
    echo "🧹 清理资源..."
    if [ -f /tmp/xvfb.pid ]; then
        local pid=$(cat /tmp/xvfb.pid)
        if ps -p $pid > /dev/null 2>&1; then
            kill $pid 2>/dev/null
            echo "✅ 虚拟显示器已停止"
        fi
        rm -f /tmp/xvfb.pid
    fi
}

# 设置退出时清理
trap cleanup EXIT

# 检查 Xvfb 是否已经运行
if pgrep -x "Xvfb" > /dev/null; then
    echo "✅ Xvfb 已经在运行"
    export DISPLAY=:99
else
    echo "🔧 启动虚拟显示器..."
    # 启动虚拟显示器
    Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
    XVFB_PID=$!
    
    # 保存 PID 以便后续清理
    echo $XVFB_PID > /tmp/xvfb.pid
    
    # 等待 Xvfb 启动
    sleep 3
    
    # 设置 DISPLAY 环境变量
    export DISPLAY=:99
    
    echo "✅ 虚拟显示器已启动 (PID: $XVFB_PID)"
fi

# 验证 zenity 是否可用
echo "🔍 测试文件对话框..."
if timeout 5s zenity --info --text="文件对话框测试成功！您现在可以使用文件选择功能了。" --width=400 --height=150 2>/dev/null; then
    echo "✅ 文件对话框功能正常"
else
    echo "⚠️  zenity测试超时或失败，但应用仍可运行"
    echo "💡 提示: 应用内置了备用文件选择方案"
fi

# 运行 Flutter 应用
echo "🏃 启动 Flutter 应用..."
echo "📝 注意: 文件选择器将在虚拟显示器上运行"
echo "🔧 如果遇到问题，请检查终端输出"
echo ""

# 设置环境变量以减少GTK警告
export GDK_BACKEND=x11
export XCURSOR_THEME=Adwaita
export XCURSOR_SIZE=24
export GTK_THEME=Adwaita

flutter run -d linux --debug
