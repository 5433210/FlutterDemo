@echo off
setlocal

echo 🐧 使用WSL构建Flutter Linux版本...
echo.

REM 检查WSL是否可用
wsl --list --quiet >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ 错误: WSL未安装或不可用
    echo 请先安装WSL和Linux发行版
    pause
    exit /b 1
)

REM 检查Arch Linux是否可用
wsl -d Arch -e echo "WSL Arch Linux 可用" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ 错误: Arch Linux WSL不可用
    echo 请确保Arch Linux WSL已安装并正常运行
    pause
    exit /b 1
)

echo ✅ WSL环境检查通过

REM 设置脚本权限并运行
echo 🔧 设置脚本权限...
wsl -d Arch -e chmod +x "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo/scripts/setup_wsl_flutter.sh"
wsl -d Arch -e chmod +x "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo/scripts/build_linux_wsl.sh"

echo.
echo 📋 可用选项:
echo 1. 设置WSL Flutter环境 (首次使用)
echo 2. 构建Linux版本 (需要先设置环境)
echo 3. 退出
echo.

set /p choice="请选择操作 (1-3): "

if "%choice%"=="1" (
    echo.
    echo 🔧 开始设置WSL Flutter环境...
    wsl -d Arch -e bash "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo/scripts/setup_wsl_flutter.sh"
    if %ERRORLEVEL% equ 0 (
        echo.
        echo ✅ WSL Flutter环境设置完成！
        echo 现在可以选择选项2来构建Linux版本
    ) else (
        echo.
        echo ❌ WSL Flutter环境设置失败
    )
) else if "%choice%"=="2" (
    echo.
    echo 🔨 开始构建Linux版本...
    wsl -d Arch -e bash "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo/scripts/build_linux_wsl.sh"
    if %ERRORLEVEL% equ 0 (
        echo.
        echo ✅ Linux版本构建完成！
        echo 📁 构建产物位置: build\linux\x64\release\bundle\
    ) else (
        echo.
        echo ❌ Linux版本构建失败
    )
) else if "%choice%"=="3" (
    echo 👋 再见！
    exit /b 0
) else (
    echo ❌ 无效选择
)

echo.
pause 