@echo off
title Android 模拟器调试环境清理工具

:main_menu
cls
echo ==========================================
echo    Android 模拟器调试环境清理工具
echo ==========================================
echo.
echo 请选择清理选项:
echo.
echo [1] 快速清理 - 只清理 Flutter 项目
echo [2] 标准清理 - 清理应用和项目缓存
echo [3] 深度清理 - 完全清理并重启模拟器
echo [4] 自定义清理 - 选择特定清理项目
echo [5] 查看当前状态
echo [0] 退出
echo.
set /p choice="请选择 (0-5): "

if "%choice%"=="1" goto quick_clean
if "%choice%"=="2" goto standard_clean
if "%choice%"=="3" goto deep_clean
if "%choice%"=="4" goto custom_clean
if "%choice%"=="5" goto show_status
if "%choice%"=="0" goto exit
goto main_menu

:quick_clean
echo.
echo 正在执行快速清理...
echo [1/2] 清理 Flutter 构建缓存...
flutter clean
echo [2/2] 重新获取依赖...
flutter pub get
echo.
echo ✅ 快速清理完成！
pause
goto main_menu

:standard_clean
echo.
echo 正在执行标准清理...
echo [1/4] 检查设备连接...
adb devices
echo [2/4] 清理应用数据...
adb shell pm clear com.example.demo
echo [3/4] 清理 Flutter 项目...
flutter clean
flutter pub get
echo [4/4] 清理 Gradle 缓存...
cd android
call gradlew clean
cd ..
echo.
echo ✅ 标准清理完成！
pause
goto main_menu

:deep_clean
echo.
echo ⚠️  警告: 深度清理将重启模拟器
set /p confirm="是否继续? (y/n): "
if not "%confirm%"=="y" goto main_menu

echo.
echo 正在执行深度清理...
echo [1/6] 卸载应用...
adb uninstall com.example.demo
echo [2/6] 清理应用数据...
adb shell pm clear com.example.demo
echo [3/6] 清理模拟器临时文件...
adb shell rm -rf /data/local/tmp/*
echo [4/6] 清理 Flutter 项目...
flutter clean
flutter pub get
echo [5/6] 清理 Gradle 缓存...
cd android
call gradlew clean
cd ..
echo [6/6] 重启模拟器...
adb reboot
echo.
echo ✅ 深度清理完成！模拟器正在重启...
pause
goto main_menu

:custom_clean
cls
echo ==========================================
echo           自定义清理选项
echo ==========================================
echo.
echo 请选择要执行的清理项目:
echo.
echo [1] 清理应用数据
echo [2] 卸载调试应用
echo [3] 清理模拟器临时文件
echo [4] 清理 Flutter 缓存
echo [5] 清理 Gradle 缓存
echo [6] 重启模拟器
echo [0] 返回主菜单
echo.
set /p custom_choice="请选择 (0-6): "

if "%custom_choice%"=="1" (
    echo 清理应用数据...
    adb shell pm clear com.example.demo
    echo 完成！
    pause
)
if "%custom_choice%"=="2" (
    echo 卸载调试应用...
    adb uninstall com.example.demo
    echo 完成！
    pause
)
if "%custom_choice%"=="3" (
    echo 清理模拟器临时文件...
    adb shell rm -rf /data/local/tmp/*
    echo 完成！
    pause
)
if "%custom_choice%"=="4" (
    echo 清理 Flutter 缓存...
    flutter clean
    flutter pub get
    echo 完成！
    pause
)
if "%custom_choice%"=="5" (
    echo 清理 Gradle 缓存...
    cd android
    call gradlew clean
    cd ..
    echo 完成！
    pause
)
if "%custom_choice%"=="6" (
    echo 重启模拟器...
    adb reboot
    echo 完成！
    pause
)
if "%custom_choice%"=="0" goto main_menu
goto custom_clean

:show_status
cls
echo ==========================================
echo           当前状态信息
echo ==========================================
echo.
echo [设备状态]
adb devices
echo.
echo [Flutter 版本]
flutter --version
echo.
echo [项目信息]
if exist "pubspec.yaml" (
    echo ✅ Flutter 项目目录
) else (
    echo ❌ 非 Flutter 项目目录
)
echo.
if exist "android\build.gradle.kts" (
    echo ✅ Android 配置存在
) else (
    echo ❌ Android 配置缺失
)
echo.
echo [缓存状态]
if exist "build\" (
    echo ⚠️  存在构建缓存
) else (
    echo ✅ 构建缓存已清理
)
echo.
pause
goto main_menu

:exit
echo.
echo 感谢使用 Android 模拟器调试环境清理工具！
pause
exit
