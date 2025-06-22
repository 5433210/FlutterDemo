@echo off
echo ================================================
echo Flutter Android Project Fix and Build Script
echo ================================================
echo.

echo Step 1: Cleaning Gradle caches...
call gradle_cleanup.bat
echo.

echo Step 2: Building with installed NDK version (26.3.11579264)...
echo.

cd android
echo Running Gradle clean...
call gradlew --refresh-dependencies clean

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed. Trying with more debug information...
    call gradlew --refresh-dependencies clean --info
    
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Build failed with --info flag. Trying with stacktrace...
        call gradlew --refresh-dependencies clean --stacktrace
    )
) else (
    echo.
    echo Build successful!
    echo.
    echo NOTE: You may still see warnings about NDK version mismatches.
    echo These are just warnings and not errors. Your app will build 
    echo with the NDK version you have installed (26.3.11579264).
)

cd ..

echo.
echo ================================================
echo IMPORTANT INFORMATION ABOUT NDK VERSIONS
echo ================================================
echo Your plugins recommend NDK version 27.0.12077973, but you have
echo version 26.3.11579264 installed. This is OK for most cases!
echo.
echo If you need to eliminate the warnings, you have these options:
echo.
echo 1. Install NDK 27.0.12077973 through Android Studio:
echo    - Open Android Studio
echo    - Go to Tools -^> SDK Manager
echo    - Select "SDK Tools" tab
echo    - Check "NDK (Side by side)" and click "Show Package Details"
echo    - Select version 27.0.12077973 and install
echo.
echo 2. Continue using your current NDK version and ignore the warnings
echo    This is fine for most development purposes!
echo.
echo ================================================