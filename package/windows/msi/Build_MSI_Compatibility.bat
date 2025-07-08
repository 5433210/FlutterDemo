@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==========================================
echo 字字珠玑 MSI 兼容性安装包构建脚本
echo （支持 Windows 7/8/10/11）
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
set "MSI_DIR=%PROJECT_ROOT%\package\windows\msi"
set "INNO_SETUP_DIR=C:\Program Files (x86)\Inno Setup 6"
set "RELEASE_DIR=%PROJECT_ROOT%\releases\windows\v1.0.1"
set "COMPAT_RELEASE_DIR=%PROJECT_ROOT%\releases\windows\v1.0.1\compatibility"
set "BUILD_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release"

echo %BLUE%=== 兼容性构建信息 ===%RESET%
echo 目标系统: Windows 7 SP1 (6.1.7600) 及以上
echo 架构: x64
echo 格式: MSI (传统安装包)
echo 输出目录: %COMPAT_RELEASE_DIR%
echo.

:: 检查 Inno Setup 是否安装
echo %BLUE%检查 Inno Setup 安装状态...%RESET%
if not exist "%INNO_SETUP_DIR%\ISCC.exe" (
    echo %RED%错误: 未找到 Inno Setup，请先安装 Inno Setup 6%RESET%
    echo 下载地址: https://jrsoftware.org/isdl.php
    pause
    exit /b 1
)
echo %GREEN%✓ Inno Setup 已安装%RESET%
echo.

:: 检查 Flutter 构建是否存在
echo %BLUE%检查 Flutter Windows 构建...%RESET%
if not exist "%BUILD_DIR%\charasgem.exe" (
    echo %YELLOW%警告: 未找到 Windows 构建文件，开始构建...%RESET%
    cd /d "%PROJECT_ROOT%"
    
    echo %BLUE%执行 Flutter 清理...%RESET%
    flutter clean
    
    echo %BLUE%获取依赖...%RESET%
    flutter pub get
    
    echo %BLUE%构建 Windows Release 版本...%RESET%
    flutter build windows --release
    
    if not exist "%BUILD_DIR%\charasgem.exe" (
        echo %RED%错误: Flutter 构建失败%RESET%
        pause
        exit /b 1
    )
)
echo %GREEN%✓ Flutter Windows 构建就绪%RESET%
echo.

:: 创建兼容性发布目录
echo %BLUE%创建兼容性发布目录...%RESET%
if not exist "%COMPAT_RELEASE_DIR%" mkdir "%COMPAT_RELEASE_DIR%"
echo %GREEN%✓ 兼容性发布目录已创建: %COMPAT_RELEASE_DIR%%RESET%
echo.

:: 创建兼容性版本的 setup.iss 副本
echo %BLUE%准备兼容性配置文件...%RESET%
set "COMPAT_SETUP_FILE=%MSI_DIR%\setup_compatibility.iss"

:: 复制原始 setup.iss 并修改输出路径
copy "%MSI_DIR%\setup.iss" "%COMPAT_SETUP_FILE%" >nul

:: 使用 PowerShell 替换输出目录
powershell -Command "& {$content = Get-Content '%COMPAT_SETUP_FILE%' -Raw; $content = $content -replace 'OutputDir=releases\\windows\\v1.0.1', 'OutputDir=releases\\windows\\v1.0.1\\compatibility'; $content = $content -replace 'OutputBaseFilename=CharAsGemInstaller_v1.0.1', 'OutputBaseFilename=CharAsGemInstaller_Legacy_v1.0.1'; Set-Content '%COMPAT_SETUP_FILE%' $content}"

echo %GREEN%✓ 兼容性配置文件已创建%RESET%
echo.

:: 验证系统兼容性设置
echo %BLUE%验证兼容性设置...%RESET%
findstr /C:"MinVersion=6.1.7600" "%COMPAT_SETUP_FILE%" >nul
if %ERRORLEVEL% equ 0 (
    echo %GREEN%✓ 最低系统版本设置为 Windows 7 SP1%RESET%
) else (
    echo %RED%❌ 兼容性设置验证失败%RESET%
    pause
    exit /b 1
)
echo.

:: 执行 Inno Setup 编译
echo %BLUE%开始编译兼容性 MSI 安装包...%RESET%
cd /d "%PROJECT_ROOT%"

"%INNO_SETUP_DIR%\ISCC.exe" /Q "%COMPAT_SETUP_FILE%"

if %ERRORLEVEL% neq 0 (
    echo %RED%错误: MSI 编译失败 (错误码: %ERRORLEVEL%)%RESET%
    echo.
    echo 可能的解决方案:
    echo 1. 检查 setup_compatibility.iss 文件语法
    echo 2. 确保所有源文件存在
    echo 3. 检查输出目录权限
    echo 4. 查看详细错误信息
    pause
    exit /b 1
)

:: 检查输出文件
set "MSI_OUTPUT=%COMPAT_RELEASE_DIR%\CharAsGemInstaller_Legacy_v1.0.1.exe"
if not exist "%MSI_OUTPUT%" (
    echo %RED%错误: 未找到编译输出文件%RESET%
    echo 预期位置: %MSI_OUTPUT%
    pause
    exit /b 1
)

echo %GREEN%✓ 兼容性 MSI 安装包编译成功！%RESET%
echo.

:: 显示文件信息
echo %BLUE%文件信息:%RESET%
for %%F in ("%MSI_OUTPUT%") do (
    echo   文件名: %%~nxF
    echo   大小: %%~zF bytes
    set /a SIZE_MB=%%~zF/1024/1024
    echo   大小: !SIZE_MB! MB
    echo   路径: %%~fF
)
echo.

:: 创建兼容性安装说明
echo %BLUE%生成兼容性安装说明...%RESET%
set "COMPAT_INSTALL_GUIDE=%COMPAT_RELEASE_DIR%\兼容性安装说明.txt"
(
echo 字字珠玑 v1.0.1 兼容性安装包
echo ================================
echo.
echo 本安装包支持以下 Windows 版本：
echo - Windows 7 SP1 ^(64位^)
echo - Windows 8 ^(64位^) 
echo - Windows 8.1 ^(64位^)
echo - Windows 10 ^(所有版本，64位^)
echo - Windows 11 ^(所有版本^)
echo.
echo 安装文件：
echo - CharAsGemInstaller_Legacy_v1.0.1.exe
echo.
echo 安装方法：
echo 1. 双击 CharAsGemInstaller_Legacy_v1.0.1.exe
echo 2. 如果出现安全警告，选择"仍要运行"
echo 3. 按照安装向导完成安装
echo.
echo 系统要求：
echo - 64位操作系统
echo - 管理员权限 ^(安装时^)
echo - 至少 100MB 可用磁盘空间
echo.
echo 注意事项：
echo 1. Windows 7 用户需要安装 SP1 更新
echo 2. 某些杀毒软件可能误报，请添加信任
echo 3. 首次运行可能需要安装 Visual C++ Redistributable
echo.
echo 卸载方法：
echo 在控制面板 ^> 程序和功能中找到"字字珠玑"并卸载
echo.
echo 技术支持：
echo 如有问题，请联系开发团队或查看项目文档。
echo.
echo 构建时间: %DATE% %TIME%
echo 兼容性级别: Legacy ^(支持 Win7+^)
) > "%COMPAT_INSTALL_GUIDE%"

echo %GREEN%✓ 兼容性安装说明已生成%RESET%
echo.

:: 复制证书文件（如果存在）
echo %BLUE%复制证书文件...%RESET%
set "CERT_SOURCE=%PROJECT_ROOT%\package\windows\msix\CharAsGem.cer"
if exist "%CERT_SOURCE%" (
    copy "%CERT_SOURCE%" "%COMPAT_RELEASE_DIR%\" >nul
    echo %GREEN%✓ 证书文件已复制%RESET%
) else (
    echo %YELLOW%⚠ 证书文件不存在，跳过复制%RESET%
)
echo.

:: 清理临时文件
if exist "%COMPAT_SETUP_FILE%" del "%COMPAT_SETUP_FILE%"

:: 生成系统兼容性测试脚本
echo %BLUE%生成系统兼容性测试脚本...%RESET%
set "COMPAT_TEST_SCRIPT=%COMPAT_RELEASE_DIR%\测试系统兼容性.bat"
(
echo @echo off
echo chcp 65001 ^>nul
echo echo ==========================================
echo echo 字字珠玑系统兼容性检查
echo echo ==========================================
echo echo.
echo.
echo :: 检查系统版本
echo for /f "tokens=2 delims=[]" %%%%G in ^('ver'^) do set "OS_VER=%%%%G"
echo echo 当前系统版本: %%OS_VER%%
echo.
echo :: 检查架构
echo echo 系统架构: %%PROCESSOR_ARCHITECTURE%%
echo if "%%PROCESSOR_ARCHITECTURE%%"=="AMD64" ^(
echo     echo ✓ 64位系统兼容
echo ^) else ^(
echo     echo ❌ 警告: 非64位系统，不兼容
echo ^)
echo.
echo :: 检查管理员权限
echo net session ^>nul 2^>^&1
echo if %%ERRORLEVEL%% equ 0 ^(
echo     echo ✓ 当前以管理员权限运行
echo ^) else ^(
echo     echo ⚠ 当前非管理员权限 ^(安装时需要提权^)
echo ^)
echo.
echo :: 检查磁盘空间 ^(C盘^)
echo for /f "tokens=3" %%%%i in ^('dir c:\ /-c ^| find "可用字节"'^) do set "FREE_SPACE=%%%%i"
echo echo 可用磁盘空间: %%FREE_SPACE%% 字节
echo.
echo :: 检查 Visual C++ Redistributable ^(可选^)
echo reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" ^>nul 2^>^&1
echo if %%ERRORLEVEL%% equ 0 ^(
echo     echo ✓ Visual C++ Redistributable 已安装
echo ^) else ^(
echo     echo ⚠ Visual C++ Redistributable 未检测到 ^(可能需要安装^)
echo ^)
echo.
echo echo 兼容性检查完成！
echo echo 如果所有项目都显示 ✓ 或 ⚠，可以继续安装。
echo echo.
echo pause
) > "%COMPAT_TEST_SCRIPT%"

echo %GREEN%✓ 兼容性测试脚本已生成%RESET%
echo.

echo %GREEN%==========================================
echo 兼容性 MSI 安装包构建完成！
echo ==========================================%RESET%
echo.

echo %BLUE%构建结果:%RESET%
echo   兼容性安装包: %MSI_OUTPUT%
echo   安装说明: %COMPAT_INSTALL_GUIDE%
echo   兼容性测试: %COMPAT_TEST_SCRIPT%
if exist "%COMPAT_RELEASE_DIR%\CharAsGem.cer" echo   数字证书: %COMPAT_RELEASE_DIR%\CharAsGem.cer
echo.

echo %BLUE%支持的系统版本:%RESET%
echo   ✓ Windows 7 SP1 (64位)
echo   ✓ Windows 8 (64位)
echo   ✓ Windows 8.1 (64位)
echo   ✓ Windows 10 (所有版本，64位)
echo   ✓ Windows 11 (所有版本)
echo.

echo %YELLOW%重要提醒:%RESET%
echo 1. Windows 7 用户建议先运行兼容性测试脚本
echo 2. 老系统可能需要额外的运行时组件
echo 3. 建议在目标系统上进行实际测试
echo.

set /p OPEN_COMPAT="是否打开兼容性发布目录？(y/N): "
if /i "!OPEN_COMPAT!"=="y" (
    explorer "%COMPAT_RELEASE_DIR%"
)

pause
