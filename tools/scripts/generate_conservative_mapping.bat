@echo off
echo 正在运行保守版ARB优化脚本...
python conservative_arb_mapping.py
echo.
echo 生成完成！请检查 arb_report/key_mapping_conservative.yaml 文件
echo 编辑完成后，请将此文件重命名为 key_mapping.yaml 并使用 apply_arb_mapping.bat 应用您的更改
echo.
pause
