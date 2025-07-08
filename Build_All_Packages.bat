@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==========================================
echo 字字珠玑 - 全平台安装包一键构建
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
set "PROJECT_ROOT=%~dp0..\.."
pushd "%PROJECT_ROOT%"
set "PROJECT_ROOT=%cd%"

echo %BLUE%项目根目录: %PROJECT_ROOT%%RESET%
echo.

:: 检查 Flutter 应用是否已构建
echo %YELLOW%步骤 1: 检查 Flutter 构建...%RESET%
if not exist "build\windows\x64\runner\Release\charasgem.exe" (
    echo %YELLOW%Flutter Windows 应用未找到，开始构建...%RESET%
    flutter build windows --release
    if !errorlevel! neq 0 (
        echo %RED%Flutter 构建失败%RESET%
        pause
        popd
        exit /b 1
    )
) else (
    echo %GREEN%✓ Flutter Windows 应用已存在%RESET%
)

echo.
echo %YELLOW%步骤 2: 构建 MSIX 安装包...%RESET%
cd /d "%PROJECT_ROOT%\package\windows\msix"
call Build_MSIX_Simple.bat
if !errorlevel! neq 0 (
    echo %RED%MSIX 构建失败%RESET%
    pause
    popd
    exit /b 1
)

echo.
echo %YELLOW%步骤 3: 构建 MSI 兼容性安装包...%RESET%
cd /d "%PROJECT_ROOT%\package\windows\msi"
call Build_MSI_Simple_Win7.bat
if !errorlevel! neq 0 (
    echo %RED%MSI 兼容包构建失败%RESET%
    pause
    popd
    exit /b 1
)

echo.
echo %GREEN%==========================================
echo 全部安装包构建完成！
echo ==========================================%RESET%
echo.

:: 显示构建结果摘要
set "RELEASE_DIR=%PROJECT_ROOT%\releases\windows\v1.0.1"
echo %BLUE%发布目录: %RELEASE_DIR%%RESET%
echo.

echo %YELLOW%MSIX 包 (Windows 10/11):%RESET%
if exist "%RELEASE_DIR%\CharAsGemInstaller_Signed_v1.0.1.msix" (
    echo %GREEN%✓ CharAsGemInstaller_Signed_v1.0.1.msix%RESET%
    for %%f in ("%RELEASE_DIR%\CharAsGemInstaller_Signed_v1.0.1.msix") do echo   大小: %%~zf 字节 (%%~zf / 1024 / 1024 MB^)
) else (
    echo %RED%✗ MSIX 包未找到%RESET%
)

echo.
echo %YELLOW%MSI 兼容包 (Windows 7/8/10/11):%RESET%
if exist "%RELEASE_DIR%\compatibility\CharAsGemInstaller_Legacy_v1.0.1.exe" (
    echo %GREEN%✓ CharAsGemInstaller_Legacy_v1.0.1.exe%RESET%
    for %%f in ("%RELEASE_DIR%\compatibility\CharAsGemInstaller_Legacy_v1.0.1.exe") do echo   大小: %%~zf 字节
) else (
    echo %RED%✗ MSI 兼容包未找到%RESET%
)

echo.
echo %YELLOW%辅助文件:%RESET%
if exist "%RELEASE_DIR%\CharAsGem.cer" echo %GREEN%✓ 自签名证书%RESET%
if exist "%RELEASE_DIR%\字字珠玑_一键安装.bat" echo %GREEN%✓ MSIX 一键安装脚本%RESET%
if exist "%RELEASE_DIR%\compatibility\安装说明.txt" echo %GREEN%✓ 兼容版安装说明%RESET%
if exist "%RELEASE_DIR%\compatibility\测试系统兼容性.bat" echo %GREEN%✓ 系统兼容性检查工具%RESET%

echo.
echo %BLUE%==========================================
echo 分发建议:
echo - Windows 10/11 用户: 使用 MSIX 包
echo - Windows 7/8 用户: 使用兼容性 MSI 包
echo - 证书安装可选，用于避免安全警告
echo ==========================================%RESET%

echo.
pause
popd
