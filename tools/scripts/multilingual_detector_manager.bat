@echo off
chcp 65001 >nul
echo ========================================
echo 多语言硬编码文本检测和替换系统
echo ========================================
echo.

:main_menu
echo 请选择操作：
echo [1] 检测中英文硬编码文本
echo [2] 查看最新检测报告
echo [3] 审核并应用映射文件
echo [4] 清理报告文件
echo [5] 显示使用帮助
echo [0] 退出
echo.
set /p choice="请输入选择 (0-5): "

if "%choice%"=="1" goto detect
if "%choice%"=="2" goto view_report
if "%choice%"=="3" goto apply_mapping
if "%choice%"=="4" goto cleanup
if "%choice%"=="5" goto help
if "%choice%"=="0" goto exit
echo 无效选择，请重试。
goto main_menu

:detect
echo.
echo === 检测硬编码文本 ===
echo 正在检测中英文硬编码文本...
python multilingual_hardcoded_detector.py --mode both --output-format yaml
if %errorlevel% equ 0 (
    echo.
    echo ✅ 检测完成！请查看生成的报告文件。
) else (
    echo.
    echo ❌ 检测失败，请检查错误信息。
)
echo.
pause
goto main_menu

:view_report
echo.
echo === 查看最新报告 ===
for /f "delims=" %%f in ('dir /b /o-d "multilingual_hardcoded_report\multilingual_summary_*.txt" 2^>nul') do (
    set latest_summary=%%f
    goto found_summary
)
echo 没有找到检测报告，请先运行检测。
goto main_menu_pause

:found_summary
echo 最新检测报告：
echo ----------------------------------------
type "multilingual_hardcoded_report\%latest_summary%"
echo ----------------------------------------
echo.
echo 详细报告文件: multilingual_hardcoded_report\%latest_summary:summary=detail%
echo 映射文件: multilingual_hardcoded_report\%latest_summary:summary_=mapping_%
echo 映射文件: multilingual_hardcoded_report\%latest_summary:summary_=mapping_%
set mapping_file=%latest_summary:summary_=mapping_%
set mapping_file=%mapping_file:.txt=.yaml%
echo 映射文件: multilingual_hardcoded_report\%mapping_file%
echo.

:main_menu_pause
pause
goto main_menu

:apply_mapping
echo.
echo === 应用映射文件 ===
for /f "delims=" %%f in ('dir /b /o-d "multilingual_hardcoded_report\multilingual_mapping_*.yaml" 2^>nul') do (
    set latest_mapping=%%f
    goto found_mapping
)
echo 没有找到映射文件，请先运行检测。
pause
goto main_menu

:found_mapping
echo 找到最新映射文件: %latest_mapping%
echo.
echo ⚠️  注意：应用映射文件前，请确保：
echo    1. 已审核所有新建的ARB键
echo    2. 已修改不合适的翻译
echo    3. 已将审核通过的条目标记为 approved: true
echo.
set /p confirm="确认要应用映射文件吗？(y/N): "
if /i not "%confirm%"=="y" goto main_menu

echo 正在应用映射文件...
python enhanced_arb_applier.py --input "multilingual_hardcoded_report\%latest_mapping%" --dry-run
if %errorlevel% equ 0 (
    echo.
    echo ✅ 映射文件应用成功！
) else (
    echo.
    echo ❌ 应用失败，请检查错误信息。
)
pause
goto main_menu

:cleanup
echo.
echo === 清理报告文件 ===
echo 将删除所有检测报告文件（保留最新的3个）
set /p confirm="确认要清理吗？(y/N): "
if /i not "%confirm%"=="y" goto main_menu

echo 正在清理旧报告文件...
for /f "skip=3 delims=" %%f in ('dir /b /o-d "multilingual_hardcoded_report\multilingual_*.txt" 2^>nul') do (
    del "multilingual_hardcoded_report\%%f"
    echo 已删除: %%f
)
for /f "skip=3 delims=" %%f in ('dir /b /o-d "multilingual_hardcoded_report\multilingual_*.yaml" 2^>nul') do (
    del "multilingual_hardcoded_report\%%f"
    echo 已删除: %%f
)
echo ✅ 清理完成！
pause
goto main_menu

:help
echo.
echo === 使用帮助 ===
echo.
echo 多语言硬编码文本检测和替换系统帮助：
echo.
echo 1. 检测功能：
echo    - 自动检测Dart代码中的中英文硬编码文本
echo    - 支持Text、hintText、labelText、tooltip等多种UI场景
echo    - 智能复用现有ARB键，减少重复翻译工作
echo    - 生成符合项目命名习惯的新键名
echo.
echo 2. 报告文件：
echo    - 汇总报告：显示检测统计信息
echo    - 详细报告：显示每个硬编码的具体位置和建议
echo    - 映射文件：用于后续自动替换的YAML格式文件
echo.
echo 3. 审核流程：
echo    - 检查建议的ARB键名是否合适
echo    - 修改自动生成的英文翻译
echo    - 将审核通过的条目标记为 approved: true
echo.
echo 4. 应用替换：
echo    - 使用enhanced_arb_applier.py应用映射文件
echo    - 支持干运行模式预览更改
echo    - 自动更新代码文件和ARB文件
echo.
echo 更多详情请参考：
echo - HARDCODED_TEXT_SYSTEM_README.md
echo - HOW_TO_REVIEW_MAPPING.md
echo.
pause
goto main_menu

:exit
echo.
echo 感谢使用多语言硬编码文本检测系统！
echo.
exit /b 0
