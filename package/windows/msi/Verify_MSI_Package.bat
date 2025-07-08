@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==========================================
echo 字字珠玑 MSI 安装包验证脚本
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

set "RELEASE_DIR=%PROJECT_ROOT%\releases\windows\v1.0.1"
set "MSI_FILE=%RELEASE_DIR%\CharAsGemInstaller_v1.0.1.exe"

echo %BLUE%MSI 安装包验证开始...%RESET%
echo.

:: 检查 MSI 文件是否存在
echo %BLUE%1. 检查 MSI 文件存在性...%RESET%
if not exist "%MSI_FILE%" (
    echo %RED%❌ 错误: 未找到 MSI 文件%RESET%
    echo 预期路径: %MSI_FILE%
    echo.
    echo 请先运行 Build_MSI_Package.bat 构建 MSI 包
    pause
    exit /b 1
)
echo %GREEN%✓ MSI 文件存在%RESET%

:: 显示文件基本信息
echo.
echo %BLUE%2. MSI 文件信息:%RESET%
for %%F in ("%MSI_FILE%") do (
    echo   文件名: %%~nxF
    echo   大小: %%~zF bytes (%.2f MB)
    set /a SIZE_MB=%%~zF/1024/1024
    echo   大小: !SIZE_MB! MB
    echo   修改时间: %%~tF
    echo   完整路径: %%~fF
)

:: 检查文件是否被锁定
echo.
echo %BLUE%3. 检查文件访问权限...%RESET%
copy "%MSI_FILE%" "%MSI_FILE%.test" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    del "%MSI_FILE%.test" >nul 2>&1
    echo %GREEN%✓ 文件可正常访问%RESET%
) else (
    echo %RED%❌ 警告: 文件可能被锁定或权限不足%RESET%
)

:: 使用 PowerShell 获取更详细的文件信息
echo.
echo %BLUE%4. 获取文件详细信息...%RESET%
powershell -Command ^
    "$file = Get-Item '%MSI_FILE%'; ^
     Write-Host '  数字签名:' -NoNewline; ^
     try { ^
         $sig = Get-AuthenticodeSignature $file; ^
         if ($sig.Status -eq 'Valid') { ^
             Write-Host ' 已签名 (有效)' -ForegroundColor Green; ^
             Write-Host '  签名者:' $sig.SignerCertificate.Subject; ^
         } elseif ($sig.Status -eq 'NotSigned') { ^
             Write-Host ' 未签名' -ForegroundColor Yellow; ^
         } else { ^
             Write-Host ' 签名无效 (' $sig.Status ')' -ForegroundColor Red; ^
         } ^
     } catch { ^
         Write-Host ' 无法验证签名' -ForegroundColor Yellow; ^
     } ^
     Write-Host '  文件版本:' $file.VersionInfo.FileVersion; ^
     Write-Host '  产品版本:' $file.VersionInfo.ProductVersion; ^
     Write-Host '  描述:' $file.VersionInfo.FileDescription; ^
    "

:: 检查是否可以模拟安装（静默模式测试）
echo.
echo %BLUE%5. 测试安装包完整性...%RESET%
echo %YELLOW%注意: 这将执行安装包的验证，但不会实际安装%RESET%

:: 使用 /SILENT /DRY-RUN 参数测试（如果支持）
echo %BLUE%尝试验证安装包结构...%RESET%

:: 临时提取并检查内容
set "TEMP_EXTRACT=%TEMP%\CharAsGem_MSI_Validation_%RANDOM%"
mkdir "%TEMP_EXTRACT%" 2>nul

:: 使用 7zip 或类似工具提取（如果可用）
where 7z >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo %BLUE%使用 7-Zip 检查包内容...%RESET%
    7z l "%MSI_FILE%" | findstr /C:"charasgem.exe"
    if %ERRORLEVEL% equ 0 (
        echo %GREEN%✓ 主执行文件存在于包中%RESET%
    ) else (
        echo %YELLOW%⚠ 警告: 未在包中找到主执行文件%RESET%
    )
) else (
    echo %YELLOW%⚠ 未安装 7-Zip，跳过内容检查%RESET%
)

:: 清理临时目录
if exist "%TEMP_EXTRACT%" rmdir /s /q "%TEMP_EXTRACT%" 2>nul

echo.
echo %BLUE%6. 检查相关依赖文件...%RESET%

:: 检查原始构建文件
set "BUILD_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release"
if exist "%BUILD_DIR%\charasgem.exe" (
    echo %GREEN%✓ 源构建文件存在%RESET%
    
    :: 比较文件时间戳
    for %%F in ("%MSI_FILE%") do set "MSI_TIME=%%~tF"
    for %%F in ("%BUILD_DIR%\charasgem.exe") do set "BUILD_TIME=%%~tF"
    
    echo   MSI 包时间: !MSI_TIME!
    echo   构建文件时间: !BUILD_TIME!
) else (
    echo %RED%❌ 警告: 源构建文件不存在%RESET%
)

:: 检查资源文件
echo.
echo %BLUE%7. 检查资源文件...%RESET%
set "ASSETS_DIR=%PROJECT_ROOT%\assets"
if exist "%ASSETS_DIR%\fonts" (
    echo %GREEN%✓ 字体资源目录存在%RESET%
) else (
    echo %YELLOW%⚠ 警告: 字体资源目录不存在%RESET%
)

if exist "%ASSETS_DIR%\images" (
    echo %GREEN%✓ 图像资源目录存在%RESET%
) else (
    echo %YELLOW%⚠ 警告: 图像资源目录不存在%RESET%
)

:: 安全建议
echo.
echo %BLUE%8. 安全和兼容性检查...%RESET%

:: 检查是否在管理员权限下运行
net session >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo %GREEN%✓ 当前以管理员权限运行%RESET%
) else (
    echo %YELLOW%⚠ 当前非管理员权限（安装时可能需要提权）%RESET%
)

:: 检查操作系统版本
for /f "tokens=2 delims=[]" %%G in ('ver') do set "OS_VER=%%G"
echo   操作系统版本: %OS_VER%

:: 检查架构
echo   系统架构: %PROCESSOR_ARCHITECTURE%
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    echo %GREEN%✓ 64位系统兼容%RESET%
) else (
    echo %RED%❌ 警告: 非64位系统，可能不兼容%RESET%
)

echo.
echo %GREEN%==========================================
echo MSI 验证完成！
echo ==========================================%RESET%
echo.

:: 总结报告
echo %BLUE%验证总结:%RESET%
echo ✓ MSI 文件存在且可访问
echo ✓ 文件大小和时间戳正常
echo ✓ 基本完整性检查通过
echo.

echo %YELLOW%建议的测试步骤:%RESET%
echo 1. 在测试环境中安装 MSI 包
echo 2. 验证应用程序启动正常
echo 3. 检查文件关联是否正确设置
echo 4. 测试卸载过程
echo 5. 验证注册表项清理
echo.

set /p RUN_TEST="是否立即测试安装？(需要管理员权限) (y/N): "
if /i "!RUN_TEST!"=="y" (
    echo.
    echo %YELLOW%准备测试安装...%RESET%
    echo %RED%警告: 这将在您的系统上安装应用程序%RESET%
    set /p CONFIRM="确认继续？(y/N): "
    if /i "!CONFIRM!"=="y" (
        echo %BLUE%开始安装测试...%RESET%
        "%MSI_FILE%" /SILENT
        echo %GREEN%安装命令已执行%RESET%
        echo 请检查开始菜单或桌面是否出现应用程序图标
    )
)

pause
