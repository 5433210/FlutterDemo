@echo off
chcp 65001 >nul
REM Android 模拟器调试环境清理脚本（简化版）

echo ==========================================
echo    Android 模拟器调试环境清理工具
echo ==========================================
echo.

REM 设置 ADB 路径
set "ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB_PATH%" (
    echo 错误: 找不到 ADB 工具
    echo 位置: %ADB_PATH%
    echo.
    echo 请确保 Android SDK 已正确安装
    pause
    exit /b 1
)

echo 使用 ADB 路径: %ADB_PATH%
echo.

REM 检查设备连接
echo [1/5] 检查连接的设备...
"%ADB_PATH%" devices
echo.

REM 清理应用（如果需要）
set /p clean_app="是否清理模拟器上的应用? (y/n): "
if /i "%clean_app%"=="y" (
    echo [2/5] 清理应用数据...
    "%ADB_PATH%" shell pm clear com.example.demo 2>nul
    "%ADB_PATH%" uninstall com.example.demo 2>nul
    echo 应用清理完成
) else (
    echo [2/5] 跳过应用清理
)

REM Flutter 清理
echo [3/5] 清理 Flutter 项目...
flutter clean
echo.

echo [4/5] 重新获取依赖...
flutter pub get
echo.

REM Gradle 清理
echo [5/5] 清理 Android Gradle 缓存...
if exist "android\gradlew.bat" (
    cd android
    call gradlew.bat clean
    cd ..
    echo Gradle 清理完成
) else (
    echo 跳过 Gradle 清理（未找到 gradlew.bat）
)

echo.
echo ✅ 清理完成！
echo.
pause
