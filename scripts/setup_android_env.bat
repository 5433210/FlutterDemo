@echo off
echo Android SDK环境变量配置脚本
echo 正在配置Android SDK环境变量...

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] 检测到管理员权限
) else (
    echo [ERROR] 需要管理员权限！
    echo 请以管理员身份运行此脚本
    pause
    exit /b 1
)

:: 设置Android SDK环境变量
setx ANDROID_HOME "C:\Users\wailik\AppData\Local\Android\Sdk" /M
setx ANDROID_SDK_ROOT "C:\Users\wailik\AppData\Local\Android\Sdk" /M

:: 添加到系统PATH
setx PATH "%PATH%;C:\Users\wailik\AppData\Local\Android\Sdk\platform-tools" /M

echo [OK] Android SDK环境变量配置完成
echo [WARNING] 请重启命令提示符使设置生效
echo.
echo [INFO] 验证环境变量:
echo ANDROID_HOME: C:\Users\wailik\AppData\Local\Android\Sdk
echo.
echo [INFO] 验证工具...
"C:\Users\wailik\AppData\Local\Android\Sdk\platform-tools\adb.exe" version >nul 2>&1 && echo [OK] ADB 可用 || echo [ERROR] ADB 需要重启生效

pause
