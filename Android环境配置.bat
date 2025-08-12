@echo off
REM Android SDK 环境变量设置工具
title Android SDK 环境配置

echo ==========================================
echo    Android SDK 环境变量设置工具
echo ==========================================
echo.

REM 检查 Android SDK 是否存在
set "ANDROID_SDK_ROOT=%LOCALAPPDATA%\Android\Sdk"
set "PLATFORM_TOOLS=%ANDROID_SDK_ROOT%\platform-tools"

if not exist "%PLATFORM_TOOLS%\adb.exe" (
    echo ❌ 错误: 找不到 Android SDK
    echo 预期位置: %PLATFORM_TOOLS%
    echo.
    echo 请确保已安装 Android Studio 和 Android SDK
    pause
    exit /b 1
)

echo ✅ 检测到 Android SDK: %ANDROID_SDK_ROOT%
echo ✅ Platform Tools: %PLATFORM_TOOLS%
echo.

REM 检查当前 PATH 中是否已包含 platform-tools
echo 检查当前环境变量...
echo %PATH% | findstr /I "platform-tools" >nul
if %ERRORLEVEL% EQ 0 (
    echo ✅ PATH 中已包含 platform-tools
    echo.
    echo 测试 ADB 命令:
    adb version
    echo.
    echo 环境配置正常！
    pause
    exit /b 0
)

echo ⚠️  PATH 中未包含 platform-tools
echo.
echo 选择配置方式:
echo [1] 临时配置 (仅当前会话有效)
echo [2] 永久配置 (需要管理员权限)
echo [0] 取消
echo.
set /p choice="请选择 (0-2): "

if "%choice%"=="1" goto temp_config
if "%choice%"=="2" goto permanent_config
if "%choice%"=="0" goto exit
goto main

:temp_config
echo.
echo 正在设置临时环境变量...
set "PATH=%PATH%;%PLATFORM_TOOLS%"
echo ✅ 临时环境变量设置完成
echo.
echo 测试 ADB 命令:
adb version
echo.
echo 注意: 此配置仅在当前命令行会话中有效
echo 关闭窗口后需要重新配置
pause
goto exit

:permanent_config
echo.
echo 正在设置永久环境变量...
echo 这需要管理员权限，可能会弹出 UAC 确认对话框

REM 使用 PowerShell 设置永久环境变量
powershell -Command "& {[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', '%ANDROID_SDK_ROOT%', 'User'); [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';%PLATFORM_TOOLS%', 'User')}"

if %ERRORLEVEL% EQ 0 (
    echo ✅ 永久环境变量设置完成
    echo.
    echo 注意: 需要重新启动命令行或重新登录系统才能生效
    echo.
    echo 你可以:
    echo 1. 重新打开命令行窗口
    echo 2. 或者重新启动计算机
    echo 3. 或者注销并重新登录
) else (
    echo ❌ 永久环境变量设置失败
    echo 请手动设置或以管理员身份运行此脚本
)

echo.
pause
goto exit

:exit
echo.
echo 退出环境配置工具
pause
