@echo off
echo ===========================================
echo     字字珠玑 MSIX 包自动化构建工具
echo ===========================================
setlocal EnableDelayedExpansion

:: 获取当前脚本目录
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\..\..\"
set "PACKAGE_DIR=%SCRIPT_DIR%"
set "VERSION_FILE=%PROJECT_ROOT%version.json"

:: 读取版本信息
echo [1/7] 读取版本信息...
if not exist "%VERSION_FILE%" (
    echo 错误: 版本文件不存在，请运行版本管理脚本
    pause
    exit /b 1
)

:: 使用PowerShell读取版本信息
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content '%VERSION_FILE%' | ConvertFrom-Json).version.major"') do set "VERSION_MAJOR=%%a"
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content '%VERSION_FILE%' | ConvertFrom-Json).version.minor"') do set "VERSION_MINOR=%%a"
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content '%VERSION_FILE%' | ConvertFrom-Json).version.patch"') do set "VERSION_PATCH=%%a"
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content '%VERSION_FILE%' | ConvertFrom-Json).version.build"') do set "VERSION_BUILD=%%a"

set "VERSION=%VERSION_MAJOR%.%VERSION_MINOR%.%VERSION_PATCH%"
set "FULL_VERSION=%VERSION%.%VERSION_BUILD%"
set "RELEASE_DIR=%PROJECT_ROOT%releases\windows\v%VERSION%"

echo 当前版本: %FULL_VERSION%
echo 输出目录: %RELEASE_DIR%

:: 创建输出目录
echo [2/7] 创建输出目录...
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"

:: 检查证书是否存在
echo [3/7] 检查证书文件...
if not exist "%PACKAGE_DIR%CharAsGem.pfx" (
    echo 证书文件不存在，正在生成...
    powershell -ExecutionPolicy Bypass -File "%PACKAGE_DIR%Generate_Certificate.ps1"
    if !errorlevel! neq 0 (
        echo 错误: 证书生成失败
        pause
        exit /b 1
    )
)

:: 复制配置文件到项目根目录
echo [4/7] 复制配置文件...
copy "%PACKAGE_DIR%msix_config.json" "%PROJECT_ROOT%msix_config.json" >nul

:: 更新配置文件版本
echo [5/7] 更新配置文件版本...
powershell -Command "$config = Get-Content '%PROJECT_ROOT%msix_config.json' | ConvertFrom-Json; $config.version = '%FULL_VERSION%'; $config.msixVersion = '%VERSION%'; $config | ConvertTo-Json -Depth 10 | Set-Content '%PROJECT_ROOT%msix_config.json'"

:: 构建 MSIX 包
echo [6/7] 构建 MSIX 包...
cd /d "%PROJECT_ROOT%"
flutter pub run msix:create
if %errorlevel% neq 0 (
    echo 错误: MSIX 构建失败
    pause
    exit /b 1
)

:: 移动生成的文件到release目录
echo [7/7] 移动文件到发布目录...
if exist "CharAsGemInstaller.msix" (
    move "CharAsGemInstaller.msix" "%RELEASE_DIR%\CharAsGemInstaller_v%VERSION%.msix"
    echo ✓ MSIX包已移动到: %RELEASE_DIR%\CharAsGemInstaller_v%VERSION%.msix
)

:: 复制证书文件到release目录
copy "%PACKAGE_DIR%CharAsGem.cer" "%RELEASE_DIR%\" >nul
copy "%PACKAGE_DIR%CharAsGem.pfx" "%RELEASE_DIR%\" >nul

:: 生成安装说明
echo [附加] 生成安装说明...
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
echo 版本信息: v%FULL_VERSION%
) > "%RELEASE_DIR%\安装说明.txt"

echo.
echo ===========================================
echo 构建完成！
echo 输出目录: %RELEASE_DIR%
echo MSIX文件: CharAsGemInstaller_v%VERSION%.msix
echo 证书文件: CharAsGem.cer
echo ===========================================
echo.

:: 验证签名匹配
echo 正在验证证书与MSIX签名匹配...
call "%PACKAGE_DIR%Verify_Certificate_MSIX_Match.bat" "%RELEASE_DIR%\CharAsGemInstaller_v%VERSION%.msix" "%PACKAGE_DIR%CharAsGem.cer"

pause
