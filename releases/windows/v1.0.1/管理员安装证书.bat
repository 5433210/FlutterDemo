@echo off
echo ===========================================
echo     管理员权限证书安装工具
echo ===========================================
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 此脚本需要管理员权限运行
    echo 请右键点击此文件，选择"以管理员身份运行"
    pause
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "CERT_FILE=%SCRIPT_DIR%CharAsGem.cer"

echo 正在以管理员权限安装证书...
echo.

if not exist "%CERT_FILE%" (
    echo ✗ 错误: 证书文件不存在: %CERT_FILE%
    pause
    exit /b 1
)

echo 安装证书到本地计算机的受信任根证书颁发机构...
certutil -addstore -f "ROOT" "%CERT_FILE%"

if %errorlevel% eq 0 (
    echo.
    echo ✓ 证书安装成功！
    echo.
    echo 现在可以安装 CharAsGemInstaller_v1.0.1_NEW.msix 文件了
    echo.
) else (
    echo.
    echo ✗ 证书安装失败
    echo 错误代码: %errorlevel%
    echo.
)

pause
