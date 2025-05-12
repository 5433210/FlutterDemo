@echo off
echo ================================================
echo 直接运行 Flutter 应用到模拟器
echo ================================================
echo.

echo 检查是否有已构建的 APK...
if not exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo 未找到构建的 APK，开始构建...
    flutter build apk --debug
) else (
    echo 找到已构建的 APK。
)

echo.
echo 尝试启动应用在连接的设备上...
echo 如果没有设备连接，将尝试启动模拟器...
echo.

REM 检查是否有设备连接
flutter devices > devices.txt
findstr /c:"android" devices.txt > nul
if errorlevel 1 (
    echo 没有找到连接的 Android 设备，将尝试启动模拟器...
    
    REM 尝试启动模拟器
    flutter emulators > emulators.txt
    findstr /c:"android" emulators.txt > nul
    if errorlevel 1 (
        echo 没有找到可用的 Android 模拟器。
        echo 请先使用 Android Studio 创建一个模拟器。
        echo 1. 打开 Android Studio
        echo 2. 点击 Tools -^> Device Manager
        echo 3. 点击 "Create Device" 并按照向导创建模拟器
        goto cleanup
    ) else (
        for /f "tokens=1" %%a in ('findstr /c:"android" emulators.txt') do (
            echo 正在启动模拟器 %%a ...
            flutter emulators --launch %%a
            timeout /t 30
            goto run_app
        )
    )
) else (
    echo 发现已连接的 Android 设备！
    goto run_app
)

:run_app
echo.
echo 正在安装并运行应用...
flutter run
goto cleanup

:cleanup
del devices.txt
del emulators.txt

echo.
echo ================================================
