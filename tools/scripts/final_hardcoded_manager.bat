@echo off
chcp 65001 >nul
echo ========================================
echo    最终硬编码文本检测和替换系统
echo ========================================
echo.

:menu
echo 请选择操作:
echo 1. 运行检测器 - 检测硬编码文本
echo 2. 查看最新检测结果
echo 3. 应用检测结果 - 替换代码和更新ARB
echo 4. 退出
echo.
set /p choice=请输入选择 (1-4): 

if "%choice%"=="1" goto detect
if "%choice%"=="2" goto view
if "%choice%"=="3" goto apply
if "%choice%"=="4" goto end
echo 无效选择，请重新输入
goto menu

:detect
echo.
echo 🔍 开始检测硬编码文本...
python final_hardcoded_detector.py
echo.
echo 检测完成！生成了以下文件:
dir final_hardcoded_report\final_*.* /B 2>nul
echo.
pause
goto menu

:view
echo.
echo 📊 最新检测结果:
if exist final_hardcoded_report\final_summary_*.txt (
    for /f %%i in ('dir final_hardcoded_report\final_summary_*.txt /B /O-D') do (
        echo 📄 汇总报告: %%i
        type final_hardcoded_report\%%i
        goto view_done
    )
) else (
    echo ❌ 没有找到检测结果，请先运行检测器
)
:view_done
echo.
pause
goto menu

:apply
echo.
echo 📝 可用的映射文件:
if exist final_hardcoded_report\final_mapping_*.yaml (
    dir final_hardcoded_report\final_mapping_*.yaml /B
    echo.
    set /p mapping_file=请输入要应用的映射文件名: 
    if exist "final_hardcoded_report\!mapping_file!" (
        echo.
        echo ⚠️  请确保已在映射文件中将需要应用的项目设置为 approved: true
        echo 💡 建议先用文本编辑器打开映射文件进行审核
        echo.
        set /p confirm=确认要应用更改吗? (y/N): 
        if /I "!confirm!"=="y" (
            python final_hardcoded_applier.py "final_hardcoded_report\!mapping_file!"
        ) else (
            echo 取消应用
        )
    ) else (
        echo ❌ 文件不存在: !mapping_file!
    )
) else (
    echo ❌ 没有找到映射文件，请先运行检测器
)
echo.
pause
goto menu

:end
echo.
echo 👋 感谢使用！
echo.
pause
exit /b
