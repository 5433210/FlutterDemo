@echo off
chcp 65001 >nul
title 字字珠玑 - 证书管理工具

echo 🔐 启动证书管理工具...
echo.

cd /d "%~dp0"
python scripts/generate_certificate.py

pause
