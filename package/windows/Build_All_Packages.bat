@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==========================================
echo 字字珠玑 Windows 安装包一键构建脚本
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
set "MSIX_DIR=%PROJECT_ROOT%\package\windows\msix"
set "MSI_DIR=%PROJECT_ROOT%\package\windows\msi"
set "RELEASE_DIR=%PROJECT_ROOT%\releases\windows\v1.0.1"

echo %BLUE%选择要构建的安装包类型:%RESET%
echo 1. 仅构建 MSIX 包
echo 2. 仅构建 MSI 包  
echo 3. 构建 MSIX 和 MSI 包
echo 4. 构建 + 签名 MSIX 和 MSI 包
echo 5. 构建兼容性 MSI 包 (支持 Win7/8)
echo 6. 构建所有格式 (MSIX + MSI + 兼容性MSI)
echo 7. 退出
echo.

set /p CHOICE="请选择 (1-7): "

if "%CHOICE%"=="1" goto :build_msix_only
if "%CHOICE%"=="2" goto :build_msi_only
if "%CHOICE%"=="3" goto :build_both
if "%CHOICE%"=="4" goto :build_both_signed
if "%CHOICE%"=="5" goto :build_compatibility_msi
if "%CHOICE%"=="6" goto :build_all_formats
if "%CHOICE%"=="7" goto :exit
goto :invalid_choice

:build_msix_only
echo.
echo %BLUE%==========================================
echo 构建 MSIX 包
echo ==========================================%RESET%
call "%MSIX_DIR%\Build_MSIX_Simple.bat"
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ MSIX 构建失败%RESET%
    pause
    exit /b 1
)
goto :completion

:build_msi_only
echo.
echo %BLUE%==========================================
echo 构建 MSI 包
echo ==========================================%RESET%
call "%MSI_DIR%\Build_MSI_Package.bat"
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ MSI 构建失败%RESET%
    pause
    exit /b 1
)
goto :completion

:build_both
echo.
echo %BLUE%==========================================
echo 构建 MSIX 和 MSI 包
echo ==========================================%RESET%

echo %BLUE%步骤 1/2: 构建 MSIX 包...%RESET%
call "%MSIX_DIR%\Build_MSIX_Simple.bat"
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ MSIX 构建失败%RESET%
    pause
    exit /b 1
)

echo.
echo %BLUE%步骤 2/2: 构建 MSI 包...%RESET%
call "%MSI_DIR%\Build_MSI_Package.bat"
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ MSI 构建失败%RESET%
    pause
    exit /b 1
)
goto :completion

:build_both_signed
echo.
echo %BLUE%==========================================
echo 构建并签名 MSIX 和 MSI 包
echo ==========================================%RESET%

echo %BLUE%步骤 1/4: 构建 MSIX 包...%RESET%
call "%MSIX_DIR%\Build_MSIX_Simple.bat"
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ MSIX 构建失败%RESET%
    pause
    exit /b 1
)

echo.
echo %BLUE%步骤 2/4: 签名 MSIX 包...%RESET%
call "%MSIX_DIR%\Manual_Sign_MSIX.bat"
if %ERRORLEVEL% neq 0 (
    echo %YELLOW%⚠ MSIX 签名失败，继续构建 MSI%RESET%
)

echo.
echo %BLUE%步骤 3/4: 构建 MSI 包...%RESET%
call "%MSI_DIR%\Build_MSI_Package.bat"
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ MSI 构建失败%RESET%
    pause
    exit /b 1
)

echo.
echo %BLUE%步骤 4/4: 签名 MSI 包...%RESET%
call "%MSI_DIR%\Sign_MSI_Package.bat"
if %ERRORLEVEL% neq 0 (
    echo %YELLOW%⚠ MSI 签名失败，但包已构建完成%RESET%
)
goto :completion

:build_compatibility_msi
echo.
echo %BLUE%==========================================
echo 构建兼容性 MSI 包 (支持 Win7/8)
echo ==========================================%RESET%
call "%MSI_DIR%\Build_MSI_Compatibility.bat"
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ 兼容性 MSI 构建失败%RESET%
    pause
    exit /b 1
)
goto :completion

:build_all_formats
echo.
echo %BLUE%==========================================
echo 构建所有格式安装包
echo ==========================================%RESET%

echo %BLUE%步骤 1/3: 构建 MSIX 包...%RESET%
call "%MSIX_DIR%\Build_MSIX_Simple.bat"
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ MSIX 构建失败%RESET%
    pause
    exit /b 1
)

echo.
echo %BLUE%步骤 2/3: 构建标准 MSI 包...%RESET%
call "%MSI_DIR%\Build_MSI_Package.bat"
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ 标准 MSI 构建失败%RESET%
    pause
    exit /b 1
)

echo.
echo %BLUE%步骤 3/3: 构建兼容性 MSI 包...%RESET%
call "%MSI_DIR%\Build_MSI_Compatibility.bat"
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ 兼容性 MSI 构建失败%RESET%
    pause
    exit /b 1
)
goto :completion

:invalid_choice
echo %RED%❌ 无效选择，请重新运行脚本%RESET%
pause
exit /b 1

:completion
echo.
echo %GREEN%==========================================
echo 构建完成！
echo ==========================================%RESET%
echo.

:: 显示构建结果
echo %BLUE%构建结果概览:%RESET%
if exist "%RELEASE_DIR%\charasgem.msix" (
    echo %GREEN%✓ MSIX 包 (Win10+): charasgem.msix%RESET%
)
if exist "%RELEASE_DIR%\CharAsGemInstaller_Signed_v1.0.1.msix" (
    echo %GREEN%✓ MSIX 包 (已签名): CharAsGemInstaller_Signed_v1.0.1.msix%RESET%
)
if exist "%RELEASE_DIR%\CharAsGemInstaller_v1.0.1.exe" (
    echo %GREEN%✓ MSI 包 (Win10+): CharAsGemInstaller_v1.0.1.exe%RESET%
)
if exist "%RELEASE_DIR%\CharAsGemInstaller_Signed_v1.0.1.exe" (
    echo %GREEN%✓ MSI 包 (已签名): CharAsGemInstaller_Signed_v1.0.1.exe%RESET%
)
if exist "%RELEASE_DIR%\compatibility\CharAsGemInstaller_Legacy_v1.0.1.exe" (
    echo %GREEN%✓ 兼容性 MSI 包 (Win7+): CharAsGemInstaller_Legacy_v1.0.1.exe%RESET%
)
if exist "%RELEASE_DIR%\CharAsGem.cer" (
    echo %GREEN%✓ 数字证书: CharAsGem.cer%RESET%
)

:: 计算总大小
echo.
echo %BLUE%文件大小统计:%RESET%
set TOTAL_SIZE=0
for %%F in ("%RELEASE_DIR%\*.msix" "%RELEASE_DIR%\*.exe") do (
    if exist "%%F" (
        for %%G in ("%%F") do (
            set /a SIZE=%%~zG/1024/1024
            echo   %%~nxG: !SIZE! MB
            set /a TOTAL_SIZE+=!SIZE!
        )
    )
)
echo   总计: %TOTAL_SIZE% MB

:: 生成安装说明
echo.
echo %BLUE%生成安装说明文档...%RESET%
set "INSTALL_GUIDE=%RELEASE_DIR%\安装说明_完整版.txt"
(
echo 字字珠玑 v1.0.1 安装包说明
echo ================================
echo.
echo 本发布包含以下安装文件：
echo.
if exist "%RELEASE_DIR%\charasgem.msix" echo 1. charasgem.msix - MSIX 格式安装包 ^(未签名^)
if exist "%RELEASE_DIR%\CharAsGemInstaller_Signed_v1.0.1.msix" echo 1. CharAsGemInstaller_Signed_v1.0.1.msix - MSIX 格式安装包 ^(已签名^)
if exist "%RELEASE_DIR%\CharAsGemInstaller_v1.0.1.exe" echo 2. CharAsGemInstaller_v1.0.1.exe - MSI 格式安装包 ^(未签名^)
if exist "%RELEASE_DIR%\CharAsGemInstaller_Signed_v1.0.1.exe" echo 2. CharAsGemInstaller_Signed_v1.0.1.exe - MSI 格式安装包 ^(已签名^)
if exist "%RELEASE_DIR%\CharAsGem.cer" echo 3. CharAsGem.cer - 数字证书文件
echo.
echo 安装方法：
echo.
echo 方法一：使用 MSIX 包 ^(推荐^)
echo 1. 如果是已签名版本，双击直接安装
echo 2. 如果是未签名版本：
echo    - 双击 CharAsGem.cer 安装证书到"受信任的根证书颁发机构"
echo    - 然后双击 MSIX 文件安装
echo.
echo 方法二：使用 MSI 包
echo 1. 双击 CharAsGemInstaller_v1.0.1.exe 开始安装
echo 2. 如果出现安全警告，选择"仍要运行"
echo 3. 如果需要，先安装 CharAsGem.cer 证书
echo.
echo 系统要求：
echo - Windows 10 版本 1709 ^(16299^) 或更高版本
echo - 64位操作系统
echo - 管理员权限 ^(安装时^)
echo.
echo 卸载方法：
echo - MSIX: 在设置 ^> 应用中找到"字字珠玑"并卸载
echo - MSI: 在控制面板 ^> 程序和功能中卸载
echo.
echo 技术支持：
echo 如有问题，请联系开发团队或查看项目文档。
echo.
echo 构建时间: %DATE% %TIME%
) > "%INSTALL_GUIDE%"

echo %GREEN%✓ 安装说明已生成: %INSTALL_GUIDE%%RESET%

:: 创建版本信息文件
set "VERSION_INFO=%RELEASE_DIR%\版本信息.txt"
(
echo 字字珠玑 v1.0.1 构建信息
echo ========================
echo.
echo 构建时间: %DATE% %TIME%
echo 构建环境: Windows
echo 目标平台: Windows 10/11 ^(x64^)
echo.
echo 包含组件:
if exist "%RELEASE_DIR%\charasgem.msix" echo - MSIX 安装包 ^(现代化部署^)
if exist "%RELEASE_DIR%\CharAsGemInstaller_v1.0.1.exe" echo - MSI 安装包 ^(传统部署^)
if exist "%RELEASE_DIR%\CharAsGem.cer" echo - 自签名证书
echo.
echo 哈希校验 ^(SHA256^):
) > "%VERSION_INFO%"

:: 计算文件哈希
echo %BLUE%计算文件校验码...%RESET%
for %%F in ("%RELEASE_DIR%\*.msix" "%RELEASE_DIR%\*.exe") do (
    if exist "%%F" (
        for /f "tokens=*" %%H in ('powershell -Command "Get-FileHash '%%F' -Algorithm SHA256 | Select-Object -ExpandProperty Hash"') do (
            echo %%~nxF: %%H >> "%VERSION_INFO%"
        )
    )
)

echo %GREEN%✓ 版本信息已生成: %VERSION_INFO%%RESET%

echo.
echo %YELLOW%后续步骤建议:%RESET%
echo 1. 在测试环境中验证安装包
echo 2. 测试应用程序功能完整性
echo 3. 验证卸载过程
echo 4. 检查系统兼容性
echo 5. 如需分发，考虑代码签名证书
echo.

set /p OPEN_RELEASE="是否打开发布目录查看结果？(y/N): "
if /i "!OPEN_RELEASE!"=="y" (
    explorer "%RELEASE_DIR%"
)

echo.
echo %GREEN%一键构建脚本执行完成！%RESET%

:exit
pause
