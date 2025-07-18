@echo off
chcp 65001 >nul
title 字字珠玑 - 多语言功能测试

echo 🌐 字字珠玑多语言功能测试工具
echo ================================
echo.

cd /d "%~dp0"

echo 📋 1. 测试 ARB 文件完整性...
python scripts/test_multilingual.py

echo.
echo 📋 2. 重新生成本地化代码...
flutter gen-l10n

echo.
echo 📋 3. 检查代码分析...
flutter analyze --no-fatal-infos

echo.
echo ✅ 多语言功能测试完成！
echo.
echo 📱 支持的语言:
echo   🇨🇳 中文 (zh) - 简体中文
echo   🇺🇸 英文 (en) - English  
echo   🇯🇵 日语 (ja) - 日本語
echo   🇰🇷 韩语 (ko) - 한국어
echo.
echo 🔧 如何测试:
echo   1. 运行应用: flutter run
echo   2. 打开设置页面
echo   3. 选择"语言"设置
echo   4. 切换不同语言测试
echo.
echo 📋 查看详细报告: 多语言功能完成报告.md
echo.
pause
