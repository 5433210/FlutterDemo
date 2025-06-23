@echo off
title WSL Flutter Linux Build Tool
color 0A

echo.
echo =========================================
echo   WSL Flutter Linux Build Tool
echo =========================================
echo.

PowerShell.exe -ExecutionPolicy Bypass -File "scripts\build_linux.ps1"

pause 