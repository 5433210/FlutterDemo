@echo off
echo ================================================
echo Android 模拟器启动和应用安装脚本
echo ================================================
echo.

echo 步骤 1: 打开 Android Studio 创建模拟器
echo 如果您尚未创建模拟器，请按照以下步骤操作:
echo  1. 打开 Android Studio
echo  2. 点击顶部菜单 "Tools" -^> "Device Manager"
echo  3. 点击 "Create Device" 创建新模拟器
echo  4. 选择设备类型 (如 Pixel 4)
echo  5. 下载并选择系统镜像 (推荐选择 Android 11 或更高版本)
echo  6. 完成模拟器配置并启动
echo.
echo 请在创建并启动模拟器后按任意键继续...
pause

echo.
echo 步骤 2: 检查设备连接状态
flutter devices
echo.
echo 如果您没有看到已连接的模拟器，请确保模拟器已启动
echo 按任意键继续安装应用...
pause

echo.
echo 步骤 3: 安装并运行应用
flutter install
echo.
echo 如果无法自动安装，可以尝试手动运行:
echo flutter run -d ^<device-id^>
echo.
echo 其中 ^<device-id^> 是您的模拟器 ID (可以从 flutter devices 命令的输出中找到)
echo.
echo 安装完成！应用应该已在模拟器上启动。
echo ================================================
