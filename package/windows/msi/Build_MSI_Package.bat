@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==========================================
echo 字字珠玑 MSI 安装包自动化构建脚本
echo ==========================================
echo.

:: 设置颜色
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "GREEN=%ESC%[32m"
set "RED=%ESC%[31m"
set "YELLOW=%ESC%[33m"
set "BLUE=%ESC%[36m"
set "RESET=%ESC%[0m"

:: 获取项目根目录
set "PROJECT_ROOT=%~dp0..\..\..\"
pushd "%PROJECT_ROOT%"
set "PROJECT_ROOT=%cd%"
popd

echo %BLUE%项目根目录: %PROJECT_ROOT%%RESET%
echo.

:: 设置相关路径
set "MSI_DIR=%PROJECT_ROOT%\package\windows\msi"
set "INNO_SETUP_DIR=C:\Program Files (x86)\Inno Setup 6"
set "RELEASE_DIR=%PROJECT_ROOT%\releases\windows\v1.0.1"
set "BUILD_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release"

:: 检查 Inno Setup 是否安装
echo %BLUE%检查 Inno Setup 安装状态...%RESET%
if not exist "%INNO_SETUP_DIR%\ISCC.exe" (
    echo %RED%错误: 未找到 Inno Setup，请先安装 Inno Setup 6%RESET%
    echo 下载地址: https://jrsoftware.org/isdl.php
    pause
    exit /b 1
)
echo %GREEN%✓ Inno Setup 已安装%RESET%
echo.

:: 检查 Flutter 构建是否存在
echo %BLUE%检查 Flutter Windows 构建...%RESET%
if not exist "%BUILD_DIR%\charasgem.exe" (
    echo %YELLOW%警告: 未找到 Windows 构建文件，开始构建...%RESET%
    cd /d "%PROJECT_ROOT%"
    
    echo %BLUE%执行 Flutter 清理...%RESET%
    flutter clean
    
    echo %BLUE%获取依赖...%RESET%
    flutter pub get
    
    echo %BLUE%构建 Windows Release 版本...%RESET%
    flutter build windows --release
    
    if not exist "%BUILD_DIR%\charasgem.exe" (
        echo %RED%错误: Flutter 构建失败%RESET%
        pause
        exit /b 1
    )
)
echo %GREEN%✓ Flutter Windows 构建就绪%RESET%
echo.

:: 创建必要的目录
echo %BLUE%创建输出目录...%RESET%
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"
echo %GREEN%✓ 输出目录已创建: %RELEASE_DIR%%RESET%
echo.

:: 检查并创建缺失的辅助文件
echo %BLUE%检查 MSI 构建所需文件...%RESET%

:: 检查 license.txt
if not exist "%MSI_DIR%\license.txt" (
    echo %YELLOW%创建 license.txt...%RESET%
    echo 字字珠玑软件许可协议 > "%MSI_DIR%\license.txt"
    echo. >> "%MSI_DIR%\license.txt"
    echo 版权所有 (C) 2025 大力出奇迹 >> "%MSI_DIR%\license.txt"
    echo. >> "%MSI_DIR%\license.txt"
    echo 本软件按"原样"提供，不提供任何明示或暗示的保证。 >> "%MSI_DIR%\license.txt"
)

:: 检查 readme.txt
if not exist "%MSI_DIR%\readme.txt" (
    echo %YELLOW%创建 readme.txt...%RESET%
    echo 欢迎使用字字珠玑！ > "%MSI_DIR%\readme.txt"
    echo. >> "%MSI_DIR%\readme.txt"
    echo 这是一款专业的汉字字体设计和练习软件。 >> "%MSI_DIR%\readme.txt"
    echo. >> "%MSI_DIR%\readme.txt"
    echo 安装完成后，您可以在开始菜单中找到"字字珠玑"应用程序。 >> "%MSI_DIR%\readme.txt"
    echo. >> "%MSI_DIR%\readme.txt"
    echo 如需帮助，请访问: https://charasgem.com/support >> "%MSI_DIR%\readme.txt"
)

:: 创建 changelog.txt（如果不存在）
if not exist "%MSI_DIR%\changelog.txt" (
    echo %YELLOW%创建 changelog.txt...%RESET%
    echo 字字珠玑更新日志 > "%MSI_DIR%\changelog.txt"
    echo. >> "%MSI_DIR%\changelog.txt"
    echo v1.0.1 (2025-01-XX) >> "%MSI_DIR%\changelog.txt"
    echo - 初始发布版本 >> "%MSI_DIR%\changelog.txt"
    echo - 支持汉字字体设计 >> "%MSI_DIR%\changelog.txt"
    echo - 集成练习功能 >> "%MSI_DIR%\changelog.txt"
    echo - Windows 11/10 兼容 >> "%MSI_DIR%\changelog.txt"
)

echo %GREEN%✓ 辅助文件检查完成%RESET%
echo.

:: 执行 Inno Setup 编译
echo %BLUE%开始编译 MSI 安装包...%RESET%
cd /d "%PROJECT_ROOT%"

"%INNO_SETUP_DIR%\ISCC.exe" /Q "%MSI_DIR%\setup.iss"

if %ERRORLEVEL% neq 0 (
    echo %RED%错误: MSI 编译失败 (错误码: %ERRORLEVEL%)%RESET%
    echo.
    echo 可能的解决方案:
    echo 1. 检查 setup.iss 文件语法
    echo 2. 确保所有源文件存在
    echo 3. 检查输出目录权限
    echo 4. 查看详细错误信息
    pause
    exit /b 1
)

:: 检查输出文件
set "MSI_OUTPUT=%RELEASE_DIR%\CharAsGemInstaller_v1.0.1.exe"
if not exist "%MSI_OUTPUT%" (
    echo %RED%错误: 未找到编译输出文件%RESET%
    echo 预期位置: %MSI_OUTPUT%
    pause
    exit /b 1
)

echo %GREEN%✓ MSI 安装包编译成功！%RESET%
echo.

:: 显示文件信息
echo %BLUE%文件信息:%RESET%
for %%F in ("%MSI_OUTPUT%") do (
    echo   文件名: %%~nxF
    echo   大小: %%~zF bytes
    echo   路径: %%~fF
)
echo.

:: 可选：复制到临时测试目录
set /p COPY_TO_TEMP="是否复制到临时目录进行测试？(y/N): "
if /i "!COPY_TO_TEMP!"=="y" (
    set "TEMP_TEST_DIR=%TEMP%\CharAsGem_MSI_Test"
    if not exist "!TEMP_TEST_DIR!" mkdir "!TEMP_TEST_DIR!"
    copy "%MSI_OUTPUT%" "!TEMP_TEST_DIR!\"
    echo %GREEN%✓ 已复制到: !TEMP_TEST_DIR!%RESET%
    
    set /p OPEN_TEMP="是否打开测试目录？(y/N): "
    if /i "!OPEN_TEMP!"=="y" (
        explorer "!TEMP_TEST_DIR!"
    )
)

echo.
echo %GREEN%==========================================
echo MSI 安装包构建完成！
echo ==========================================%RESET%
echo.
echo 输出文件: %MSI_OUTPUT%
echo.
echo 后续步骤:
echo 1. 测试安装包安装过程
echo 2. 验证应用程序功能
echo 3. 检查文件关联和注册表项
echo 4. (可选) 进行代码签名
echo.

set /p OPEN_RELEASE="是否打开发布目录？(y/N): "
if /i "!OPEN_RELEASE!"=="y" (
    explorer "%RELEASE_DIR%"
)

pause
