@echo off
chcp 65001 >nul
title 字字珠玑 - 发布管理工具

echo 📦 启动发布管理工具...
echo.

cd /d "%~dp0"
python scripts/release_manager.py --interactive

pause
