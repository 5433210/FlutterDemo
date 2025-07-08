@echo off
setlocal EnableDelayedExpansion

echo ===========================================
echo     字字珠玑 MSIX 包自动化构建工具
echo ===========================================

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\..\..\"
set "PACKAGE_DIR=%SCRIPT_DIR%"
set "VERSION=1.0.1"
set "RELEASE_DIR=%PROJECT_ROOT%releases\windows\v%VERSION%"

echo 项目根目录: %PROJECT_ROOT%
echo 包目录: %PACKAGE_DIR%
echo 版本: %VERSION%
echo 输出目录: %RELEASE_DIR%
echo.

echo [1/5] 创建输出目录...
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"

echo [2/5] 检查证书文件...
if not exist "%PACKAGE_DIR%CharAsGem.pfx" (
    echo 错误: PFX证书文件不存在
    pause
    exit /b 1
)
echo ✓ 证书文件存在

echo [3/5] 复制配置文件到项目根目录...
copy "%PACKAGE_DIR%msix_config.json" "%PROJECT_ROOT%msix_config.json" >nul
echo ✓ 配置文件已复制

echo [4/5] 构建 MSIX 包...
cd /d "%PROJECT_ROOT%"
flutter pub run msix:create
if %errorlevel% neq 0 (
    echo ✗ MSIX 构建失败
    pause
    exit /b 1
)
echo ✓ MSIX 构建完成

echo [5/5] 移动文件到发布目录...
if exist "CharAsGemInstaller.msix" (
    move "CharAsGemInstaller.msix" "%RELEASE_DIR%\CharAsGemInstaller_v%VERSION%.msix" >nul
    echo ✓ MSIX包已移动到: %RELEASE_DIR%\CharAsGemInstaller_v%VERSION%.msix
) else (
    echo ⚠ 未找到生成的MSIX文件
)

:: 复制证书文件
copy "%PACKAGE_DIR%CharAsGem.cer" "%RELEASE_DIR%\" >nul
copy "%PACKAGE_DIR%CharAsGem.pfx" "%RELEASE_DIR%\" >nul
echo ✓ 证书文件已复制

:: 生成安装说明
echo 生成安装说明...
(
echo 字字珠玑 v%VERSION% 安装包
echo ===============================
echo.
echo 安装文件:
echo - CharAsGemInstaller_v%VERSION%.msix ^(主安装包^)
echo - CharAsGem.cer ^(证书文件^)
echo.
echo 安装步骤:
echo 1. 双击 CharAsGem.cer 安装证书到"受信任的根证书颁发机构"
echo 2. 双击 CharAsGemInstaller_v%VERSION%.msix 安装应用
echo.
echo 生成时间: %date% %time%
echo 版本信息: v%VERSION%
) > "%RELEASE_DIR%\安装说明.txt"

echo.
echo ===========================================
echo ✓ 构建完成！
echo ===========================================
echo 输出目录: %RELEASE_DIR%
echo MSIX文件: CharAsGemInstaller_v%VERSION%.msix
echo 证书文件: CharAsGem.cer
echo ===========================================

pause
