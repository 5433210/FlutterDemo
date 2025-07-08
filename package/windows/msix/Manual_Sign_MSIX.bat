@echo off
setlocal EnableDelayedExpansion

echo ===========================================
echo     MSIX手动签名工具
echo ===========================================

set "MSIX_FILE=%1"
set "SCRIPT_DIR=%~dp0"

if "%MSIX_FILE%"=="" (
    echo 用法: %0 ^<MSIX文件路径^>
    pause
    exit /b 1
)

if not exist "%MSIX_FILE%" (
    echo 错误: MSIX文件不存在: %MSIX_FILE%
    pause
    exit /b 1
)

:: 检查证书文件
set "PFX_FILE=%SCRIPT_DIR%CharAsGem.pfx"
if not exist "%PFX_FILE%" (
    echo 错误: PFX证书文件不存在，正在生成...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Generate_Certificate.ps1"
    if !errorlevel! neq 0 (
        echo 错误: 证书生成失败
        pause
        exit /b 1
    )
)

:: 查找signtool
echo 正在查找signtool.exe...
set "SIGNTOOL="
for %%p in (
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\signtool.exe"
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.18362.0\x64\signtool.exe"
    "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64\signtool.exe"
) do (
    if exist "%%~p" (
        set "SIGNTOOL=%%~p"
        goto :found_signtool
    )
)

:: 尝试从PATH查找
signtool.exe sign /? >nul 2>&1
if %errorlevel% eq 0 (
    set "SIGNTOOL=signtool.exe"
    goto :found_signtool
)

echo 错误: 未找到signtool.exe
echo 请安装Windows SDK或Visual Studio
pause
exit /b 1

:found_signtool
echo 找到signtool: %SIGNTOOL%

:: 创建临时备份
echo 创建MSIX备份...
set "BACKUP_FILE=%MSIX_FILE%.backup"
copy "%MSIX_FILE%" "%BACKUP_FILE%" >nul

:: 执行签名
echo 正在使用证书签名MSIX包...
"%SIGNTOOL%" sign /f "%PFX_FILE%" /fd SHA256 /t http://timestamp.digicert.com "%MSIX_FILE%"

if %errorlevel% eq 0 (
    echo ✓ MSIX包签名成功
    del "%BACKUP_FILE%" >nul 2>&1
    
    :: 验证签名
    echo 验证签名...
    "%SIGNTOOL%" verify /pa "%MSIX_FILE%"
    
    if !errorlevel! eq 0 (
        echo ✓ 签名验证成功
    ) else (
        echo ⚠ 签名验证失败，但文件已签名
    )
) else (
    echo ✗ MSIX包签名失败
    echo 恢复备份文件...
    move "%BACKUP_FILE%" "%MSIX_FILE%" >nul
    pause
    exit /b 1
)

echo.
echo ===========================================
echo ✓ MSIX包已成功重新签名
echo ===========================================
pause
