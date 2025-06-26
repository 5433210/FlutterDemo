@echo off
REM 词匹配模式调试日志过滤脚本 (Windows版本)
REM 使用方法: flutter run -d windows --debug 2>&1 | powershell -File filter_word_matching_debug.ps1

echo === 词匹配模式调试日志过滤器 ===
echo 正在监听包含 [WORD_MATCHING_DEBUG] 的日志...
echo ===========================================

:loop
set /p line=
if "%line%" == "" goto end
echo %line% | findstr /C:"[WORD_MATCHING_DEBUG]" >nul
if %errorlevel% == 0 (
    echo [%time%] %line%
)
goto loop

:end
