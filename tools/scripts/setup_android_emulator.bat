@echo off
echo ================================================
echo 安装 Android 系统镜像并创建模拟器
echo ================================================
echo.

set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk

echo 正在安装 Android 系统镜像 (Android 11, x86_64)...
echo 这个过程可能需要几分钟，具体取决于您的网络连接速度。
echo.

"%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" "system-images;android-30;google_apis;x86_64"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo 系统镜像安装失败。
    echo 请尝试使用 Android Studio 手动安装:
    echo  1. 打开 Android Studio
    echo  2. 点击 Tools -^> SDK Manager
    echo  3. 选择 "SDK Tools" 标签
    echo  4. 找到并安装 "Android Emulator" 和 "Android SDK Platform-Tools"
    echo  5. 选择 "SDK Platforms" 标签
    echo  6. 选择 Android 11 (API Level 30)
    echo  7. 勾选 "Show Package Details"
    echo  8. 选择并安装 "System Image" (推荐 x86_64 架构的 Google APIs)
    exit /b 1
)

echo.
echo 系统镜像安装完成，现在创建模拟器...
echo.

"%ANDROID_HOME%\cmdline-tools\latest\bin\avdmanager.bat" create avd --name "flutter_emulator" --package "system-images;android-30;google_apis;x86_64" --device "pixel_4"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo 模拟器创建失败。
    echo 请尝试使用 Android Studio 手动创建:
    echo  1. 打开 Android Studio
    echo  2. 点击 Tools -^> Device Manager
    echo  3. 点击 "Create Device"
    echo  4. 选择设备类型 (如 Pixel 4)
    echo  5. 选择系统镜像 (Android 11 with Google APIs)
    echo  6. 完成创建过程
    exit /b 1
)

echo.
echo ================================================
echo 模拟器创建成功！
echo.
echo 您现在可以运行以下命令启动模拟器:
echo   flutter emulators --launch flutter_emulator
echo.
echo 或者运行提供的脚本:
echo   run_on_android.bat
echo ================================================
