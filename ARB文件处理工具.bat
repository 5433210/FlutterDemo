@echo off
chcp 65001 >nul
title 字字珠玑 - ARB 文件处理工具

echo 🌐 启动 ARB 文件处理工具...
echo.

cd /d "%~dp0"
python scripts/process_arb.py

echo.
echo 📋 生成本地化代码...
flutter gen-l10n

echo.
echo ✅ ARB 文件处理完成！
pause
