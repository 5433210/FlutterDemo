@echo off
setlocal EnableDelayedExpansion

echo ==========================================
echo    字字珠玑 MSIX 一键部署工具
echo ==========================================

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\..\..\"

echo 项目目录: %PROJECT_ROOT%
echo.

echo [1/4] 生成/更新证书...
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Generate_Certificate.ps1"
if %errorlevel% neq 0 (
    echo ✗ 证书生成失败
    pause
    exit /b 1
)

echo [2/4] 构建 MSIX 包...
call "%SCRIPT_DIR%Build_MSIX_Package.bat"
if %errorlevel% neq 0 (
    echo ✗ MSIX构建失败
    pause
    exit /b 1
)

echo [3/4] 验证签名匹配...
for /f "tokens=*" %%a in ('dir /b "%PROJECT_ROOT%releases\windows\v*" 2^>nul') do set "LATEST_VERSION=%%a"
if "%LATEST_VERSION%"=="" (
    echo ✗ 未找到发布版本目录
    pause
    exit /b 1
)

set "RELEASE_DIR=%PROJECT_ROOT%releases\windows\%LATEST_VERSION%"
for /f "tokens=*" %%a in ('dir /b "%RELEASE_DIR%\*.msix" 2^>nul') do set "MSIX_FILE=%%a"
if "%MSIX_FILE%"=="" (
    echo ✗ 未找到MSIX文件
    pause
    exit /b 1
)

call "%SCRIPT_DIR%Verify_Certificate_MSIX_Match.bat" "%RELEASE_DIR%\%MSIX_FILE%" "%SCRIPT_DIR%CharAsGem.cer" --silent
if %errorlevel% neq 0 (
    echo ⚠ 签名不匹配，尝试手动重新签名...
    call "%SCRIPT_DIR%Manual_Sign_MSIX.bat" "%RELEASE_DIR%\%MSIX_FILE%"
    if !errorlevel! neq 0 (
        echo ✗ 手动签名失败
        pause
        exit /b 1
    )
    
    :: 再次验证
    call "%SCRIPT_DIR%Verify_Certificate_MSIX_Match.bat" "%RELEASE_DIR%\%MSIX_FILE%" "%SCRIPT_DIR%CharAsGem.cer" --silent
    if !errorlevel! neq 0 (
        echo ✗ 重新签名后仍然不匹配
        pause
        exit /b 1
    )
)

echo [4/4] 运行诊断检查...
call "%SCRIPT_DIR%Certificate_Diagnosis_Fix.bat"

echo.
echo ==========================================
echo ✓ 部署完成！
echo ==========================================
echo 发布目录: %RELEASE_DIR%
echo MSIX文件: %MSIX_FILE%
echo 证书文件: CharAsGem.cer
echo ==========================================
echo.
echo 安装步骤:
echo 1. 安装证书: 双击 CharAsGem.cer 并安装到"受信任的根证书颁发机构"
echo 2. 安装应用: 双击 %MSIX_FILE%
echo.

:: 询问是否打开发布目录
choice /c YN /m "是否打开发布目录? (Y/N)"
if %errorlevel% eq 1 (
    explorer "%RELEASE_DIR%"
)

pause
