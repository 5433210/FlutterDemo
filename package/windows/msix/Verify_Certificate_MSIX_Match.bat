@echo off
setlocal EnableDelayedExpansion

echo ===========================================
echo   证书与MSIX签名匹配验证工具
echo ===========================================

set "MSIX_FILE=%1"
set "CERT_FILE=%2"

if "%MSIX_FILE%"=="" (
    echo 用法: %0 ^<MSIX文件路径^> ^<证书文件路径^>
    pause
    exit /b 1
)

if "%CERT_FILE%"=="" (
    echo 用法: %0 ^<MSIX文件路径^> ^<证书文件路径^>
    pause
    exit /b 1
)

if not exist "%MSIX_FILE%" (
    echo 错误: MSIX文件不存在: %MSIX_FILE%
    pause
    exit /b 1
)

if not exist "%CERT_FILE%" (
    echo 错误: 证书文件不存在: %CERT_FILE%
    pause
    exit /b 1
)

echo 正在验证文件:
echo MSIX: %MSIX_FILE%
echo 证书: %CERT_FILE%
echo.

:: 获取MSIX包的签名信息
echo [1/3] 获取MSIX包签名信息...
powershell -Command "try { $sig = Get-AuthenticodeSignature '%MSIX_FILE%'; if ($sig.SignerCertificate) { Write-Host '✓ MSIX包已签名'; Write-Host '签名者: ' $sig.SignerCertificate.Subject; Write-Host '指纹: ' $sig.SignerCertificate.Thumbprint; $env:MSIX_THUMBPRINT = $sig.SignerCertificate.Thumbprint } else { Write-Host '✗ MSIX包未签名或签名无效'; exit 1 } } catch { Write-Host '✗ 无法读取MSIX签名信息'; exit 1 }"

if %errorlevel% neq 0 (
    echo 验证失败: 无法获取MSIX签名信息
    pause
    exit /b 1
)

:: 获取证书信息
echo [2/3] 获取证书信息...
powershell -Command "try { $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2('%CERT_FILE%'); Write-Host '✓ 证书读取成功'; Write-Host '主体: ' $cert.Subject; Write-Host '指纹: ' $cert.Thumbprint; $env:CERT_THUMBPRINT = $cert.Thumbprint } catch { Write-Host '✗ 无法读取证书信息'; exit 1 }"

if %errorlevel% neq 0 (
    echo 验证失败: 无法读取证书信息
    pause
    exit /b 1
)

:: 比较指纹
echo [3/3] 比较证书指纹...
powershell -Command "if ($env:MSIX_THUMBPRINT -eq $env:CERT_THUMBPRINT) { Write-Host '✓ 证书与MSIX签名完全匹配!' -ForegroundColor Green; exit 0 } else { Write-Host '✗ 证书与MSIX签名不匹配!' -ForegroundColor Red; Write-Host 'MSIX指纹: ' $env:MSIX_THUMBPRINT; Write-Host '证书指纹: ' $env:CERT_THUMBPRINT; exit 1 }"

if %errorlevel% eq 0 (
    echo.
    echo ===========================================
    echo ✓ 验证成功: 证书与MSIX签名完全匹配
    echo ===========================================
) else (
    echo.
    echo ===========================================
    echo ✗ 验证失败: 证书与MSIX签名不匹配
    echo   需要重新签名MSIX包
    echo ===========================================
)

echo.
if not "%3"=="--silent" pause
exit /b %errorlevel%
