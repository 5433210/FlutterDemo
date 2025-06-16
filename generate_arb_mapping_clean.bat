@echo off
echo 正在运行ARB优化脚本（无行内注释版）...
python enhanced_arb_mapping.py
echo.
echo 生成完成！请检查 arb_report/key_mapping.yaml 文件
echo 编辑完成后，使用 apply_arb_mapping.bat 应用您的更改
echo.
pause
