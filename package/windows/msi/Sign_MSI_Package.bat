@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==========================================
echo 字字珠玑 MSI 数字签名脚本
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

set "MSIX_CERT_DIR=%PROJECT_ROOT%\package\windows\msix"
set "MSI_DIR=%PROJECT_ROOT%\package\windows\msi"
set "RELEASE_DIR=%PROJECT_ROOT%\releases\windows\v1.0.1"
set "MSI_FILE=%RELEASE_DIR%\CharAsGemInstaller_v1.0.1.exe"
set "SIGNED_MSI_FILE=%RELEASE_DIR%\CharAsGemInstaller_Signed_v1.0.1.exe"

echo %BLUE%MSI 数字签名开始...%RESET%
echo.

:: 检查 MSI 文件是否存在
echo %BLUE%1. 检查 MSI 文件...%RESET%
if not exist "%MSI_FILE%" (
    echo %RED%❌ 错误: 未找到 MSI 文件%RESET%
    echo 预期路径: %MSI_FILE%
    echo.
    echo 请先运行 Build_MSI_Package.bat 构建 MSI 包
    pause
    exit /b 1
)
echo %GREEN%✓ MSI 文件存在%RESET%

:: 检查证书文件
echo.
echo %BLUE%2. 检查数字证书...%RESET%
set "CERT_FILE=%MSIX_CERT_DIR%\CharAsGem.pfx"
set "CER_FILE=%MSIX_CERT_DIR%\CharAsGem.cer"

if not exist "%CERT_FILE%" (
    echo %RED%❌ 错误: 未找到 PFX 证书文件%RESET%
    echo 预期路径: %CERT_FILE%
    echo.
    echo 请确保证书文件存在，或运行证书生成脚本
    pause
    exit /b 1
)

if not exist "%CER_FILE%" (
    echo %RED%❌ 错误: 未找到 CER 证书文件%RESET%
    echo 预期路径: %CER_FILE%
    pause
    exit /b 1
)

echo %GREEN%✓ 证书文件存在%RESET%

:: 检查 SignTool
echo.
echo %BLUE%3. 检查签名工具...%RESET%

:: 查找 SignTool 路径
set "SIGNTOOL_PATH="
for %%P in (
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64\signtool.exe"
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\signtool.exe"
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.18362.0\x64\signtool.exe"
    "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64\signtool.exe"
    "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.7.2 Tools\x64\signtool.exe"
) do (
    if exist "%%~P" (
        set "SIGNTOOL_PATH=%%~P"
        goto :found_signtool
    )
)

:: 检查 PATH 中的 signtool
where signtool >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "tokens=*" %%i in ('where signtool') do (
        set "SIGNTOOL_PATH=%%i"
        goto :found_signtool
    )
)

echo %RED%❌ 错误: 未找到 SignTool.exe%RESET%
echo.
echo SignTool 通常随 Windows SDK 或 Visual Studio 一起安装
echo 请安装 Windows SDK 或 Visual Studio Build Tools
echo.
echo 下载地址:
echo - Windows SDK: https://developer.microsoft.com/windows/downloads/windows-sdk/
echo - Visual Studio Build Tools: https://visualstudio.microsoft.com/visual-cpp-build-tools/
pause
exit /b 1

:found_signtool
echo %GREEN%✓ 找到 SignTool: %SIGNTOOL_PATH%%RESET%

:: 检查当前 MSI 签名状态
echo.
echo %BLUE%4. 检查当前签名状态...%RESET%
"%SIGNTOOL_PATH%" verify /pa "%MSI_FILE%" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo %YELLOW%⚠ MSI 文件已有有效签名%RESET%
) else (
    echo %GREEN%✓ MSI 文件未签名，可以进行签名%RESET%
)

:: 获取证书密码
echo.
echo %BLUE%5. 准备签名参数...%RESET%
set /p CERT_PASSWORD="请输入证书密码（如果设置了）: "

:: 执行签名
echo.
echo %BLUE%6. 开始数字签名...%RESET%

if "%CERT_PASSWORD%"=="" (
    set "SIGN_COMMAND="%SIGNTOOL_PATH%" sign /f "%CERT_FILE%" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v "%MSI_FILE%""
) else (
    set "SIGN_COMMAND="%SIGNTOOL_PATH%" sign /f "%CERT_FILE%" /p "%CERT_PASSWORD%" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v "%MSI_FILE%""
)

echo %YELLOW%执行签名命令...%RESET%
%SIGN_COMMAND%

if %ERRORLEVEL% neq 0 (
    echo %RED%❌ 签名失败 (错误码: %ERRORLEVEL%)%RESET%
    echo.
    echo 可能的原因:
    echo 1. 证书密码错误
    echo 2. 证书文件损坏
    echo 3. 网络连接问题（时间戳服务器）
    echo 4. 文件被占用
    echo.
    echo 尝试不使用时间戳服务器再次签名...
    if "%CERT_PASSWORD%"=="" (
        "%SIGNTOOL_PATH%" sign /f "%CERT_FILE%" /fd SHA256 /v "%MSI_FILE%"
    ) else (
        "%SIGNTOOL_PATH%" sign /f "%CERT_FILE%" /p "%CERT_PASSWORD%" /fd SHA256 /v "%MSI_FILE%"
    )
    
    if %ERRORLEVEL% neq 0 (
        echo %RED%❌ 签名仍然失败%RESET%
        pause
        exit /b 1
    )
)

echo %GREEN%✓ 签名成功！%RESET%

:: 验证签名
echo.
echo %BLUE%7. 验证签名...%RESET%
"%SIGNTOOL_PATH%" verify /pa /v "%MSI_FILE%"

if %ERRORLEVEL% equ 0 (
    echo %GREEN%✓ 签名验证成功！%RESET%
) else (
    echo %RED%❌ 签名验证失败%RESET%
    echo 签名可能存在问题，但文件已签名
)

:: 创建签名版本副本
echo.
echo %BLUE%8. 创建签名版本副本...%RESET%
copy "%MSI_FILE%" "%SIGNED_MSI_FILE%" >nul
if %ERRORLEVEL% equ 0 (
    echo %GREEN%✓ 已创建签名版本: %SIGNED_MSI_FILE%%RESET%
) else (
    echo %YELLOW%⚠ 警告: 无法创建副本%RESET%
)

:: 显示签名信息
echo.
echo %BLUE%9. 签名信息详情...%RESET%
powershell -Command ^
    "try { ^
         $sig = Get-AuthenticodeSignature '%MSI_FILE%'; ^
         Write-Host '签名状态:' $sig.Status; ^
         Write-Host '签名者:' $sig.SignerCertificate.Subject; ^
         Write-Host '时间戳:' $sig.TimeStamperCertificate.NotAfter; ^
         Write-Host '哈希算法:' $sig.HashAlgorithm; ^
     } catch { ^
         Write-Host '无法获取签名详情' -ForegroundColor Red; ^
     }"

:: 复制证书到发布目录
echo.
echo %BLUE%10. 复制证书文件...%RESET%
copy "%CER_FILE%" "%RELEASE_DIR%\" >nul
if %ERRORLEVEL% equ 0 (
    echo %GREEN%✓ 已复制证书文件到发布目录%RESET%
) else (
    echo %YELLOW%⚠ 警告: 无法复制证书文件%RESET%
)

echo.
echo %GREEN%==========================================
echo MSI 数字签名完成！
echo ==========================================%RESET%
echo.

:: 显示结果文件
echo %BLUE%输出文件:%RESET%
if exist "%SIGNED_MSI_FILE%" (
    echo   已签名 MSI: %SIGNED_MSI_FILE%
) else (
    echo   已签名 MSI: %MSI_FILE%
)
echo   证书文件: %RELEASE_DIR%\CharAsGem.cer
echo.

echo %YELLOW%安装说明:%RESET%
echo 1. 双击安装 MSI 文件
echo 2. 如果出现安全警告，点击"仍要运行"
echo 3. 如果需要安装证书，双击 CharAsGem.cer 文件
echo 4. 将证书安装到"受信任的根证书颁发机构"
echo.

set /p OPEN_RELEASE="是否打开发布目录？(y/N): "
if /i "!OPEN_RELEASE!"=="y" (
    explorer "%RELEASE_DIR%"
)

pause
