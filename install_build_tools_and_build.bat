@echo off
echo ================================================
echo 安装 Android SDK Build-Tools 34.0.0
echo ================================================
echo.

set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
if not exist "%ANDROID_HOME%" set ANDROID_HOME=%USERPROFILE%\AppData\Local\Android\Sdk

if not exist "%ANDROID_HOME%" (
    echo 找不到 Android SDK 位置。
    echo 请先安装 Android SDK 或设置 ANDROID_HOME 环境变量。
    exit /b 1
)

echo 使用 Android SDK 路径: %ANDROID_HOME%
echo.

REM 检查 cmdline-tools 是否存在
if exist "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" (
    echo 开始安装 Android SDK Build-Tools 34.0.0...
    echo 请稍候，这可能需要一些时间...
    echo.
    
    call "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" "build-tools;34.0.0"
    
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo 通过命令行安装失败，请通过 Android Studio 手动安装。
        echo 1. 打开 Android Studio
        echo 2. 进入 Tools -^> SDK Manager
        echo 3. 选择 "SDK Tools" 选项卡
        echo 4. 勾选 "Android SDK Build-Tools" 并安装版本 34.0.0
        exit /b 1
    )
    
    echo.
    echo Android SDK Build-Tools 34.0.0 安装完成！
) else (
    echo 找不到 SDK Manager。请通过 Android Studio 手动安装必要的组件。
    exit /b 1
)

echo.
echo ================================================
echo 继续构建 Android 应用
echo ================================================
echo.

cd %~dp0
cd android
call gradlew.bat assembleDebug

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo 构建失败，请查看错误信息并修复问题。
    exit /b 1
) else (
    echo.
    echo 构建成功！APK 文件位于:
    echo %~dp0build\app\outputs\apk\debug\app-debug.apk
)

echo.
