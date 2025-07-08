@echo off
chcp 65001 >nul
echo =====================
echo System Compatibility Check
echo =====================
echo.
echo System Information:
ver
echo.
echo Processor Architecture: %PROCESSOR_ARCHITECTURE%
echo.

echo Checking .NET Framework...
reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✓ .NET Framework 4.0+ is installed
) else (
    echo ✗ .NET Framework 4.0+ not found
    echo   You may need to install .NET Framework 4.8
)
echo.

echo Checking Visual C++ Runtime...
if exist "C:\Windows\System32\msvcp140.dll" (
    echo ✓ Visual C++ 2015-2022 Runtime is installed
) else (
    echo ✗ Visual C++ 2015-2022 Runtime not found
    echo   You may need to install Visual C++ Redistributable
)
echo.

echo Checking system architecture...
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    echo ✓ 64-bit system detected - Compatible
) else (
    echo ⚠ 32-bit system detected
    echo   This application requires 64-bit Windows
    echo   Installation may fail
)
echo.

echo Checking Windows version...
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%VERSION%"=="6.1" echo Windows 7 detected - Ensure SP1 is installed
if "%VERSION%"=="6.2" echo Windows 8 detected
if "%VERSION%"=="6.3" echo Windows 8.1 detected
if "%VERSION%"=="10.0" echo Windows 10/11 detected
echo.

echo Disk space check...
for /f "tokens=3" %%a in ('dir /-c "%SystemDrive%\" ^| find "bytes free"') do set FREESPACE=%%a
echo Free space on %SystemDrive%: %FREESPACE% bytes
echo Required: ~80 MB (80,000,000 bytes)
echo.

echo =====================
echo Compatibility Summary
echo =====================
echo - Run this installer as Administrator
echo - Ensure antivirus is not blocking the installer
echo - Close other programs before installation
echo - Have internet connection for dependency downloads
echo.
pause
