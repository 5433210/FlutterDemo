@echo off
chcp 65001 >nul
title 字字珠玑 - 多平台构建工具

echo 🎯 启动多平台构建工具...
echo.

cd /d "%~dp0"
python scripts/build_release.py --interactive

pause
