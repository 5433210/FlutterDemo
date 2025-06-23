@echo off
echo Windows SDK工具PATH配置脚本
echo 正在添加Windows SDK工具到系统PATH...

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

:: 添加到系统PATH
setx PATH "%PATH%;C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64" /M

echo [OK] 已添加 Windows SDK 工具到系统PATH
echo [WARNING] 请重启命令提示符使设置生效
echo.
echo [INFO] 验证工具...
signtool >nul 2>&1 && echo [OK] SignTool 可用 || echo [ERROR] SignTool 需要重启生效
makeappx >nul 2>&1 && echo [OK] MakeAppx 可用 || echo [ERROR] MakeAppx 需要重启生效

pause
