@echo off
REM Android 模拟器调试环境清理脚本
echo ======================================
echo Android 模拟器调试环境清理工具
echo ======================================

REM 设置 ADB 路径
set "ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB_PATH%" (
    echo 错误: 找不到 ADB 工具
    echo 请检查 Android SDK 是否正确安装
    pause
    exit /b 1
)

REM 检查是否有连接的设备
echo 正在检查连接的设备...
"%ADB_PATH%" devices

REM 获取应用包名
set APP_PACKAGE=com.example.demo
echo 应用包名: %APP_PACKAGE%

REM 清理应用数据
echo [2/6] 清理应用数据...
"%ADB_PATH%" shell pm clear %APP_PACKAGE%
if %ERRORLEVEL% NEQ 0 (
    echo 警告: 清理应用数据失败，可能应用未安装
)

REM 卸载应用
echo [3/6] 卸载调试版本应用...
"%ADB_PATH%" uninstall %APP_PACKAGE%
if %ERRORLEVEL% NEQ 0 (
    echo 警告: 卸载应用失败，可能应用未安装
)

REM 清理临时文件
echo [4/6] 清理模拟器临时文件...
"%ADB_PATH%" shell rm -rf /data/local/tmp/*
"%ADB_PATH%" shell rm -rf /sdcard/Android/data/%APP_PACKAGE%

REM Flutter 项目清理
echo [5/6] 清理 Flutter 项目...
flutter clean
flutter pub get

REM Gradle 清理
echo [6/6] 清理 Android Gradle 缓存...
cd android
call gradlew clean
cd ..

REM 重启模拟器
echo [7/7] 重启模拟器...
echo 警告: 即将重启模拟器，请确认
pause
"%ADB_PATH%" reboot

echo.
echo ✅ 清理完成！
echo 模拟器重启后，调试环境已完全清理
pause
