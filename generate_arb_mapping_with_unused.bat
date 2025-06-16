@echo off
echo 正在运行ARB优化脚本（包含未使用键标记）...
python enhanced_arb_mapping_with_unused.py
echo.
echo 生成完成！请检查 arb_report/key_mapping.yaml 文件
echo 注意：文件中标记为 [UNUSED] 的键是未使用的键，可以考虑删除
echo 编辑完成后，使用 apply_arb_mapping.bat 应用您的更改
echo.
pause
