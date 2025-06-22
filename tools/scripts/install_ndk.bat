@echo off
echo Installing NDK 27.0.12077973 through Android SDK Manager
echo This may take some time depending on your internet connection speed

set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
if not exist "%ANDROID_HOME%" set ANDROID_HOME=%USERPROFILE%\AppData\Local\Android\Sdk

if not exist "%ANDROID_HOME%" (
    echo Cannot find Android SDK location.
    echo Please install Android SDK first or set ANDROID_HOME environment variable.
    exit /b 1
)

echo Using Android SDK at: %ANDROID_HOME%
echo.
echo Running SDK Manager to install NDK 27.0.12077973...
echo.

"%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" "ndk;27.0.12077973"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Error installing NDK. Please try manually from Android Studio:
    echo 1. Open Android Studio
    echo 2. Go to Tools -^> SDK Manager
    echo 3. Select "SDK Tools" tab
    echo 4. Check "NDK (Side by side)" and install version 27.0.12077973
    exit /b 1
)

echo.
echo NDK installation complete! You can now build your Flutter project.
echo.
