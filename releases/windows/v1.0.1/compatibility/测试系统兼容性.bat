@echo off
chcp 65001 >nul
echo =====================
echo 系统兼容性检查
echo =====================
echo.
ver
echo.
echo 检查 .NET Framework...
reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release 2>nul || echo 未安装 .NET Framework 4.0+
echo.
echo 检查 Visual C++ 运行库...
dir "C:\Windows\System32\msvcp140.dll" 2>nul && echo ✓ VC++ 2015-2022 已安装 || echo ✗ 可能需要安装 VC++ 运行库
echo.
echo 检查系统架构...
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" ( echo ✓ 64位系统 ) else ( echo ⚠ 32位系统，可能存在兼容性问题 )
echo.
pause
