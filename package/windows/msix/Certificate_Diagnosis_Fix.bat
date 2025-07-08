@echo off
setlocal EnableDelayedExpansion

echo ===========================================
echo   0x800B0109证书信任问题诊断修复工具
echo ===========================================

set "SCRIPT_DIR=%~dp0"
set "CERT_FILE=%SCRIPT_DIR%CharAsGem.cer"
set "PFX_FILE=%SCRIPT_DIR%CharAsGem.pfx"

echo [1/8] 检查证书文件...
if not exist "%CERT_FILE%" (
    echo ⚠ 证书文件不存在，正在生成...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Generate_Certificate.ps1"
    if !errorlevel! neq 0 (
        echo ✗ 证书生成失败
        pause
        exit /b 1
    )
)

echo ✓ 证书文件存在: %CERT_FILE%

echo [2/8] 检查证书存储状态...
powershell -Command "try { $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2('%CERT_FILE%'); $store = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', 'LocalMachine'); $store.Open('ReadOnly'); $found = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }; $store.Close(); if ($found) { Write-Host '✓ 证书已安装在受信任的根证书颁发机构' } else { Write-Host '⚠ 证书未安装在受信任的根证书颁发机构' }; $env:CERT_INSTALLED = if ($found) { 'true' } else { 'false' } } catch { Write-Host '✗ 无法检查证书状态' }"

if "%CERT_INSTALLED%"=="false" (
    echo [3/8] 安装证书到受信任的根证书颁发机构...
    powershell -Command "Start-Process -FilePath 'certlm.msc' -Verb RunAs"
    echo 请在证书管理器中手动将证书导入到"受信任的根证书颁发机构"
    echo 或者运行以下命令（需要管理员权限）:
    echo certutil -addstore -f "ROOT" "%CERT_FILE%"
    pause
) else (
    echo ✓ 证书已正确安装
)

echo [4/8] 检查当前用户证书存储...
powershell -Command "try { $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2('%CERT_FILE%'); $store = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', 'CurrentUser'); $store.Open('ReadOnly'); $found = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }; $store.Close(); if ($found) { Write-Host '✓ 证书已安装在当前用户的受信任根证书' } else { Write-Host '⚠ 证书未安装在当前用户的受信任根证书，正在安装...'; $store = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', 'CurrentUser'); $store.Open('ReadWrite'); $store.Add($cert); $store.Close(); Write-Host '✓ 证书已安装到当前用户' } } catch { Write-Host '✗ 当前用户证书操作失败' }"

echo [5/8] 检查Windows开发者模式...
powershell -Command "try { $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'; $devMode = Get-ItemProperty -Path $regPath -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction SilentlyContinue; if ($devMode.AllowDevelopmentWithoutDevLicense -eq 1) { Write-Host '✓ 开发者模式已启用' } else { Write-Host '⚠ 开发者模式未启用，建议启用以便安装未签名的应用' } } catch { Write-Host '✗ 无法检查开发者模式状态' }"

echo [6/8] 检查应用安装权限...
powershell -Command "try { $regPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx'; $allowSideload = Get-ItemProperty -Path $regPath -Name 'AllowAllTrustedApps' -ErrorAction SilentlyContinue; if ($allowSideload.AllowAllTrustedApps -eq 1) { Write-Host '✓ 允许安装受信任的应用' } else { Write-Host '⚠ 可能限制了受信任应用的安装' } } catch { Write-Host '✓ 没有发现应用安装限制策略' }"

echo [7/8] 清理应用包缓存...
powershell -Command "try { Get-AppxPackage | Where-Object { $_.Name -like '*CharAsGem*' } | Remove-AppxPackage -ErrorAction SilentlyContinue; Write-Host '✓ 已清理旧的应用包' } catch { Write-Host '⚠ 清理应用包时出现问题' }"

echo [8/8] 生成修复建议...
echo.
echo ===========================================
echo               修复建议
echo ===========================================
echo.
echo 如果仍然遇到0x800B0109错误，请按以下步骤操作:
echo.
echo 1. 以管理员身份运行命令提示符
echo 2. 执行: certutil -addstore -f "ROOT" "%CERT_FILE%"
echo 3. 重启计算机
echo 4. 重新尝试安装MSIX包
echo.
echo 或者:
echo 1. 双击 %CERT_FILE% 
echo 2. 点击"安装证书"
echo 3. 选择"本地计算机"
echo 4. 选择"将所有的证书都放入下列存储"
echo 5. 浏览选择"受信任的根证书颁发机构"
echo 6. 完成安装
echo.
echo ===========================================

:: 创建修复脚本
echo 创建一键修复脚本...
(
echo @echo off
echo echo 正在以管理员权限安装证书...
echo certutil -addstore -f "ROOT" "%CERT_FILE%"
echo if %%errorlevel%% eq 0 ^(
echo     echo ✓ 证书安装成功
echo ^) else ^(
echo     echo ✗ 证书安装失败
echo ^)
echo pause
) > "%SCRIPT_DIR%Fix_Certificate_Admin.bat"

echo ✓ 已创建管理员修复脚本: Fix_Certificate_Admin.bat
echo.
pause
