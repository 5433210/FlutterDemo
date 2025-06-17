@echo off
chcp 65001 > nul
echo ================================
echo 硬编码文本检测和替换系统
echo ================================
echo.

:menu
echo 请选择操作:
echo 1. 综合检测 (UI文本 + 枚举显示名称)
echo 2. 仅检测UI文本硬编码
echo 3. 仅检测枚举显示名称
echo 4. 应用映射文件 (执行替换)
echo 5. 查看最新检测报告
echo 6. 退出
echo.
set /p choice=请输入选择 (1-6):

if "%choice%"=="1" goto comprehensive
if "%choice%"=="2" goto ui_only
if "%choice%"=="3" goto enum_only
if "%choice%"=="4" goto apply
if "%choice%"=="5" goto view_report
if "%choice%"=="6" goto exit
echo 无效选择，请重新输入
goto menu

:comprehensive
echo.
echo 开始综合检测硬编码文本 (UI文本 + 枚举显示名称)...
python comprehensive_hardcoded_manager.py
echo.
echo 综合检测完成！请查看生成的综合映射文件。
echo 审核并修改英文翻译，将需要处理的条目的 approved 设置为 true。
echo 然后选择选项4执行替换。
echo.
pause
goto menu

:ui_only
echo.
echo 开始检测UI文本硬编码...
python enhanced_hardcoded_detector.py
echo.
echo UI文本检测完成！请查看生成的映射文件。
echo.
pause
goto menu

:enum_only
echo.
echo 开始检测枚举显示名称硬编码...
python enum_display_detector.py
echo.
echo 枚举检测完成！请查看生成的映射文件。
echo.
pause
goto menu

:detect
echo.
echo 开始检测硬编码文本...
python enhanced_hardcoded_detector.py
echo.
echo 检测完成！请查看生成的映射文件，审核并修改英文翻译。
echo 将需要处理的条目的 approved 设置为 true，然后选择选项2执行替换。
echo.
pause
goto menu

:apply
echo.
echo 开始应用映射文件...
echo 将自动查找最新的映射文件。
echo.
echo 可用的映射文件类型:
echo - comprehensive_mapping_*.yaml (综合映射文件)
echo - hardcoded_mapping_*.yaml (UI文本映射文件)
echo - enum_mapping_*.yaml (枚举映射文件)
echo.
python enhanced_arb_applier.py --auto-latest
echo.
echo 应用完成！建议运行 flutter gen-l10n 更新本地化文件。
echo.
pause
goto menu

:report_only
echo.
echo 生成检测报告（仅查看）...
python enhanced_hardcoded_detector.py
echo.
echo 报告生成完成！请查看 hardcoded_detection_report 目录。
echo.
pause
goto menu

:view_report
echo.
echo 打开报告目录...
echo 检查以下目录中的报告:
if exist "comprehensive_hardcoded_report" (
    echo - 综合检测报告目录: comprehensive_hardcoded_report
    explorer comprehensive_hardcoded_report
)
if exist "hardcoded_detection_report" (
    echo - UI文本检测报告目录: hardcoded_detection_report
    explorer hardcoded_detection_report
)
if exist "enum_detection_report" (
    echo - 枚举检测报告目录: enum_detection_report
    explorer enum_detection_report
)
if not exist "comprehensive_hardcoded_report" if not exist "hardcoded_detection_report" if not exist "enum_detection_report" (
    echo 报告目录不存在，请先运行检测。
)
echo.
pause
goto menu

:exit
echo 感谢使用！
pause
