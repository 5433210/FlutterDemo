@echo off
echo ===== 应用ARB映射（支持未使用键处理） =====
echo.

:: Check if Python is installed
where python >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Python not found. Please install Python 3.6 or later.
    exit /b 1
)

:: Check if the YAML file exists
if not exist "arb_report\key_mapping.yaml" (
    echo Error: YAML mapping file not found.
    echo Please run generate_arb_mapping_with_unused.bat first to create the mapping file.
    exit /b 1
)

:: Show options
echo 选择操作模式:
echo 1. 仅应用键值映射（保留未使用的键）
echo 2. 应用键值映射并删除未使用的键
echo 3. 取消
echo.

set /p choice=请输入您的选择 (1-3): 

if "%choice%"=="1" (
    echo.
    echo 正在应用键值映射（保留未使用的键）...
    python apply_arb_mapping_with_unused.py
) else if "%choice%"=="2" (
    echo.
    echo 警告: 这将删除所有标记为 [UNUSED] 的键！
    echo 请确保您已经检查过这些键确实不再需要。
    echo.
    set /p confirm=确认删除未使用的键？ (y/N): 
    if /i "%confirm%"=="y" (
        echo.
        echo 正在应用键值映射并删除未使用的键...
        python apply_arb_mapping_with_unused.py --remove-unused
    ) else (
        echo 操作已取消。
    )
) else if "%choice%"=="3" (
    echo 操作已取消。
) else (
    echo 无效选择。
    exit /b 1
)

echo.
if %ERRORLEVEL% EQU 0 (
    echo ✅ ARB映射应用成功！
    echo 文件已自动备份到带时间戳的文件夹中。
) else (
    echo ⚠️ ARB映射应用过程中出现问题，请检查输出信息。
)

echo.
pause
