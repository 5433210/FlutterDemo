@echo off
chcp 65001 >nul
setlocal

echo [WSL] Building Flutter Linux version...
echo.

REM Check if WSL is available
wsl --list --quiet >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] WSL not installed or unavailable
    echo Please install WSL and Linux distribution first
    pause
    exit /b 1
)

REM Check if Arch Linux is available  
wsl -d Arch -e echo "WSL Arch Linux available" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Arch Linux WSL unavailable
    echo Please ensure Arch Linux WSL is installed and running
    pause
    exit /b 1
)

echo [OK] WSL environment check passed

REM Set script permissions and run
echo [INFO] Setting script permissions...
wsl -d Arch -e chmod +x "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo/scripts/setup_wsl_flutter.sh"
wsl -d Arch -e chmod +x "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo/scripts/build_linux_wsl.sh"

echo.
echo Available options:
echo 1. Setup WSL Flutter environment (first time use)
echo 2. Build Linux version (requires environment setup first)
echo 3. Exit
echo.

set /p choice="Please select operation (1-3): "

if "%choice%"=="1" (
    echo.
    echo [INFO] Setting up WSL Flutter environment...
    wsl -d Arch -e bash "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo/scripts/setup_wsl_flutter.sh"
    if %ERRORLEVEL% equ 0 (
        echo.
        echo [SUCCESS] WSL Flutter environment setup completed!
        echo You can now select option 2 to build Linux version
    ) else (
        echo.
        echo [ERROR] WSL Flutter environment setup failed
    )
) else if "%choice%"=="2" (
    echo.
    echo [INFO] Starting Linux version build...
    wsl -d Arch -e bash "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo/scripts/build_linux_wsl.sh"
    if %ERRORLEVEL% equ 0 (
        echo.
        echo [SUCCESS] Linux version build completed!
        echo [INFO] Build artifacts location: build\linux\x64\release\bundle\
    ) else (
        echo.
        echo [ERROR] Linux version build failed
    )
) else if "%choice%"=="3" (
    echo Goodbye!
    exit /b 0
) else (
    echo [ERROR] Invalid selection
)

echo.
pause 