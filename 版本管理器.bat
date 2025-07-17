@echo off
chcp 65001 >nul
title 字字珠玑 - 版本管理器

echo 🎯 启动版本管理器...
echo.

cd /d "%~dp0"
python scripts/version_manager.py

pause
