@echo off
REM 快速 Android 模拟器清理工具
cd /d "%~dp0"

echo ======================================
echo    快速 Android 模拟器清理工具
echo ======================================
echo.

REM 检查是否在正确的目录
if not exist "pubspec.yaml" (
    echo 错误: 请在 Flutter 项目根目录运行此脚本
    pause
    exit /b 1
)

echo 正在执行快速清理操作...
echo.

REM 执行 Flutter 清理
echo [1/3] 清理 Flutter 构建缓存...
flutter clean

REM 重新获取依赖
echo [2/3] 重新获取项目依赖...
flutter pub get

REM 可选: 清理设备上的应用
set /p clean_device="是否清理模拟器上的应用数据? (y/n): "
if /i "%clean_device%"=="y" (
    echo [3/3] 清理模拟器应用数据...
    adb shell pm clear com.example.demo 2>nul
    echo 应用数据清理完成
) else (
    echo [3/3] 跳过模拟器清理
)

echo.
echo ✅ 快速清理完成！
echo 现在可以重新运行 Flutter 应用了
echo.
pause
