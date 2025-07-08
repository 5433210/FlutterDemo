@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==========================================
echo 字字珠玑 MSI 兼容性安装包构建 (简化版)
echo ==========================================
echo.

:: 设置颜色
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "GREEN=%ESC%[32m"
set "RED=%ESC%[31m"
set "YELLOW=%ESC%[33m"
set "BLUE=%ESC%[36m"
set "RESET=%ESC%[0m"

:: 获取项目根目录并切换
set "PROJECT_ROOT=%~dp0..\..\..\"
pushd "%PROJECT_ROOT%"
set "PROJECT_ROOT=%cd%"

echo %BLUE%当前工作目录: %PROJECT_ROOT%%RESET%

:: 设置路径
set "MSI_DIR=%PROJECT_ROOT%\package\windows\msi"
set "INNO_SETUP_DIR=C:\Program Files (x86)\Inno Setup 6"
set "COMPAT_RELEASE_DIR=%PROJECT_ROOT%\releases\windows\v1.0.1\compatibility"

:: 检查并创建输出目录
if not exist "%COMPAT_RELEASE_DIR%" mkdir "%COMPAT_RELEASE_DIR%"

:: 检查 Inno Setup
if not exist "%INNO_SETUP_DIR%\ISCC.exe" (
    echo %RED%错误: 未找到 Inno Setup%RESET%
    pause
    popd
    exit /b 1
)

:: 切换到 MSI 目录（很重要，确保相对路径正确）
cd /d "%MSI_DIR%"
echo %BLUE%当前目录: %CD%%RESET%

:: 创建临时配置文件
set "TEMP_CONFIG=temp_setup_win7.iss"

:: 复制并修改配置
copy "setup.iss" "%TEMP_CONFIG%" >nul

echo %YELLOW%开始编译 MSI 安装包...%RESET%

:: 编译 MSI 包
"%INNO_SETUP_DIR%\ISCC.exe" "%TEMP_CONFIG%"

if !errorlevel! neq 0 (
    echo %RED%MSI 编译失败%RESET%
    del "%TEMP_CONFIG%" 2>nul
    pause
    popd
    exit /b 1
)

:: 删除临时文件
del "%TEMP_CONFIG%" 2>nul

:: 检查输出文件是否在正确位置
set "OUTPUT_FILE=%COMPAT_RELEASE_DIR%\CharAsGemInstaller_Legacy_v1.0.1.exe"
if exist "%OUTPUT_FILE%" (
    echo %GREEN%✓ MSI 安装包生成成功: %OUTPUT_FILE%%RESET%
    dir "%OUTPUT_FILE%" | findstr "CharAsGemInstaller_Legacy"
) else (
    echo %RED%✗ MSI 安装包未找到%RESET%
    echo 期望位置: %OUTPUT_FILE%
    echo 检查其他可能位置...
    dir "%MSI_DIR%\*.exe" 2>nul
    if exist "%MSI_DIR%\CharAsGemInstaller_Legacy_v1.0.1.exe" (
        echo %YELLOW%发现文件在 MSI 目录，正在移动...%RESET%
        move "%MSI_DIR%\CharAsGemInstaller_Legacy_v1.0.1.exe" "%OUTPUT_FILE%"
        if exist "%OUTPUT_FILE%" (
            echo %GREEN%✓ 文件移动成功%RESET%
        )
    )
)

:: 复制证书文件
if exist "%PROJECT_ROOT%\package\windows\msix\CharAsGem.cer" (
    copy "%PROJECT_ROOT%\package\windows\msix\CharAsGem.cer" "%COMPAT_RELEASE_DIR%\" >nul
    echo %GREEN%✓ 证书文件已复制%RESET%
)

:: 生成安装说明
echo 创建安装说明文件...
(
echo 字字珠玑 - Windows 兼容性安装包 v1.0.1
echo =====================================
echo.
echo 系统要求:
echo - Windows 7 SP1 及以上版本
echo - Windows 8/8.1/10/11
echo.
echo 安装步骤:
echo 1. 双击 CharAsGemInstaller_Legacy_v1.0.1.exe 开始安装
echo 2. 如果出现安全警告，点击"更多信息"然后"仍要运行"
echo 3. 按照安装向导完成安装
echo.
echo 证书安装（可选）:
echo 1. 双击 CharAsGem.cer 证书文件
echo 2. 点击"安装证书"
echo 3. 选择"本地计算机"
echo 4. 将证书放入"受信任的根证书颁发机构"
echo.
echo 注意事项:
echo - 此为兼容性版本，支持较老的 Windows 系统
echo - 如果您使用 Windows 10/11，建议使用 MSIX 版本
echo.
echo 技术支持: 字字珠玑开发团队
) > "%COMPAT_RELEASE_DIR%\安装说明.txt"

:: 生成系统兼容性测试脚本
(
echo @echo off
echo chcp 65001 ^>nul
echo echo =====================
echo echo 系统兼容性检查
echo echo =====================
echo echo.
echo ver
echo echo.
echo echo 检查 .NET Framework...
echo reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release 2^>nul ^|^| echo 未安装 .NET Framework 4.0+
echo echo.
echo echo 检查 Visual C++ 运行库...
echo dir "C:\Windows\System32\msvcp140.dll" 2^>nul ^&^& echo ✓ VC++ 2015-2022 已安装 ^|^| echo ✗ 可能需要安装 VC++ 运行库
echo echo.
echo echo 检查系统架构...
echo if "%%PROCESSOR_ARCHITECTURE%%"=="AMD64" ^( echo ✓ 64位系统 ^) else ^( echo ⚠ 32位系统，可能存在兼容性问题 ^)
echo echo.
echo pause
) > "%COMPAT_RELEASE_DIR%\测试系统兼容性.bat"

:: 生成构建报告
(
echo # 字字珠玑 Windows 兼容性安装包构建报告
echo.
echo ## 构建信息
echo - 构建时间: %date% %time%
echo - 版本: v1.0.1
echo - 包类型: MSI ^(Inno Setup^)
echo - 目标系统: Windows 7/8/10/11
echo.
echo ## 文件列表
echo - CharAsGemInstaller_Legacy_v1.0.1.exe ^(安装包^)
echo - CharAsGem.cer ^(自签名证书^)
echo - 安装说明.txt ^(安装指南^)
echo - 测试系统兼容性.bat ^(系统检查工具^)
echo.
echo ## 兼容性说明
echo - 最低系统要求: Windows 7 SP1
echo - 推荐系统: Windows 10/11
echo - 架构支持: x64
echo.
echo ## 安装方式
echo 1. 下载兼容性安装包 ^(本目录^)
echo 2. 执行安装程序
echo 3. 可选安装证书以避免安全警告
echo.
echo ## 技术细节
echo - 打包工具: Inno Setup 6.x
echo - 签名: 自签名证书
echo - 压缩: 标准压缩
) > "%COMPAT_RELEASE_DIR%\构建报告.md"

echo.
echo %GREEN%==========================================
echo 兼容性安装包构建完成！
echo ==========================================%RESET%
echo.
echo %BLUE%输出目录: %COMPAT_RELEASE_DIR%%RESET%
echo.
echo 生成的文件:
if exist "%OUTPUT_FILE%" echo %GREEN%✓ CharAsGemInstaller_Legacy_v1.0.1.exe%RESET%
if exist "%COMPAT_RELEASE_DIR%\CharAsGem.cer" echo %GREEN%✓ CharAsGem.cer%RESET%
if exist "%COMPAT_RELEASE_DIR%\安装说明.txt" echo %GREEN%✓ 安装说明.txt%RESET%
if exist "%COMPAT_RELEASE_DIR%\测试系统兼容性.bat" echo %GREEN%✓ 测试系统兼容性.bat%RESET%
if exist "%COMPAT_RELEASE_DIR%\构建报告.md" echo %GREEN%✓ 构建报告.md%RESET%

echo.
pause
popd
pause
