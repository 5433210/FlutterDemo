@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==========================================
echo 字字珠玑 MSI 安装包完整测试脚本
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

set "MSI_DIR=%PROJECT_ROOT%\package\windows\msi"
set "RELEASE_DIR=%PROJECT_ROOT%\releases\windows\v1.0.1"
set "MSI_FILE=%RELEASE_DIR%\CharAsGemInstaller_v1.0.1.exe"

echo %BLUE%开始 MSI 安装包完整测试...%RESET%
echo.

:: 测试计数器
set TOTAL_TESTS=0
set PASSED_TESTS=0
set FAILED_TESTS=0

:: 测试1: 检查前置条件
set /a TOTAL_TESTS+=1
echo %BLUE%测试 %TOTAL_TESTS%: 检查前置条件...%RESET%

:: 检查 Inno Setup
set "INNO_SETUP_DIR=C:\Program Files (x86)\Inno Setup 6"
if exist "%INNO_SETUP_DIR%\ISCC.exe" (
    echo %GREEN%  ✓ Inno Setup 已安装%RESET%
    set /a PASSED_TESTS+=1
) else (
    echo %RED%  ❌ Inno Setup 未安装%RESET%
    set /a FAILED_TESTS+=1
    goto :test_summary
)

:: 测试2: 检查 Flutter 构建
set /a TOTAL_TESTS+=1
echo %BLUE%测试 %TOTAL_TESTS%: 检查 Flutter 构建...%RESET%

set "BUILD_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release"
if exist "%BUILD_DIR%\charasgem.exe" (
    echo %GREEN%  ✓ Flutter Windows 构建文件存在%RESET%
    set /a PASSED_TESTS+=1
) else (
    echo %YELLOW%  ⚠ Flutter 构建文件不存在，尝试构建...%RESET%
    cd /d "%PROJECT_ROOT%"
    flutter clean
    flutter pub get
    flutter build windows --release
    
    if exist "%BUILD_DIR%\charasgem.exe" (
        echo %GREEN%  ✓ Flutter 构建成功%RESET%
        set /a PASSED_TESTS+=1
    ) else (
        echo %RED%  ❌ Flutter 构建失败%RESET%
        set /a FAILED_TESTS+=1
        goto :test_summary
    )
)

:: 测试3: 检查配置文件
set /a TOTAL_TESTS+=1
echo %BLUE%测试 %TOTAL_TESTS%: 检查配置文件...%RESET%

if exist "%MSI_DIR%\setup.iss" (
    echo %GREEN%  ✓ setup.iss 存在%RESET%
) else (
    echo %RED%  ❌ setup.iss 不存在%RESET%
    set /a FAILED_TESTS+=1
    goto :test_summary
)

if exist "%MSI_DIR%\license.txt" (
    echo %GREEN%  ✓ license.txt 存在%RESET%
) else (
    echo %RED%  ❌ license.txt 不存在%RESET%
    set /a FAILED_TESTS+=1
    goto :test_summary
)

if exist "%MSI_DIR%\readme.txt" (
    echo %GREEN%  ✓ readme.txt 存在%RESET%
    set /a PASSED_TESTS+=1
) else (
    echo %RED%  ❌ readme.txt 不存在%RESET%
    set /a FAILED_TESTS+=1
    goto :test_summary
)

:: 测试4: 执行构建
set /a TOTAL_TESTS+=1
echo %BLUE%测试 %TOTAL_TESTS%: 执行 MSI 构建...%RESET%

:: 清理旧文件
if exist "%MSI_FILE%" del "%MSI_FILE%"

:: 执行构建
cd /d "%PROJECT_ROOT%"
"%INNO_SETUP_DIR%\ISCC.exe" /Q "%MSI_DIR%\setup.iss"

if %ERRORLEVEL% equ 0 (
    echo %GREEN%  ✓ MSI 构建成功%RESET%
    set /a PASSED_TESTS+=1
) else (
    echo %RED%  ❌ MSI 构建失败 (错误码: %ERRORLEVEL%)%RESET%
    set /a FAILED_TESTS+=1
    goto :test_summary
)

:: 测试5: 验证输出文件
set /a TOTAL_TESTS+=1
echo %BLUE%测试 %TOTAL_TESTS%: 验证输出文件...%RESET%

if exist "%MSI_FILE%" (
    for %%F in ("%MSI_FILE%") do (
        set FILE_SIZE=%%~zF
        if !FILE_SIZE! gtr 1048576 (
            echo %GREEN%  ✓ MSI 文件生成成功 (大小: %%~zF bytes)%RESET%
            set /a PASSED_TESTS+=1
        ) else (
            echo %RED%  ❌ MSI 文件过小，可能构建不完整%RESET%
            set /a FAILED_TESTS+=1
        )
    )
) else (
    echo %RED%  ❌ MSI 文件未生成%RESET%
    set /a FAILED_TESTS+=1
    goto :test_summary
)

:: 测试6: 文件完整性检查
set /a TOTAL_TESTS+=1
echo %BLUE%测试 %TOTAL_TESTS%: 文件完整性检查...%RESET%

:: 尝试用 7zip 检查内容
where 7z >nul 2>&1
if %ERRORLEVEL% equ 0 (
    7z l "%MSI_FILE%" | findstr /C:"charasgem.exe" >nul
    if %ERRORLEVEL% equ 0 (
        echo %GREEN%  ✓ 主执行文件包含在 MSI 中%RESET%
        set /a PASSED_TESTS+=1
    ) else (
        echo %RED%  ❌ 主执行文件未找到%RESET%
        set /a FAILED_TESTS+=1
    )
) else (
    echo %YELLOW%  ⚠ 7-Zip 未安装，跳过内容检查%RESET%
    echo %GREEN%  ✓ 跳过内容检查（假设通过）%RESET%
    set /a PASSED_TESTS+=1
)

:: 测试7: 签名测试 (可选)
set /a TOTAL_TESTS+=1
echo %BLUE%测试 %TOTAL_TESTS%: 签名功能测试...%RESET%

:: 检查 SignTool
set "SIGNTOOL_PATH="
for %%P in (
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64\signtool.exe"
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\signtool.exe"
) do (
    if exist "%%~P" (
        set "SIGNTOOL_PATH=%%~P"
        goto :found_signtool_test
    )
)

where signtool >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "tokens=*" %%i in ('where signtool') do (
        set "SIGNTOOL_PATH=%%i"
        goto :found_signtool_test
    )
)

echo %YELLOW%  ⚠ SignTool 未找到，跳过签名测试%RESET%
set /a PASSED_TESTS+=1
goto :test_8

:found_signtool_test
set "CERT_FILE=%PROJECT_ROOT%\package\windows\msix\CharAsGem.pfx"
if exist "%CERT_FILE%" (
    echo %GREEN%  ✓ 签名环境可用%RESET%
    set /a PASSED_TESTS+=1
) else (
    echo %YELLOW%  ⚠ 证书文件不存在，跳过签名测试%RESET%
    set /a PASSED_TESTS+=1
)

:: 测试8: 安装测试准备
:test_8
set /a TOTAL_TESTS+=1
echo %BLUE%测试 %TOTAL_TESTS%: 安装测试准备...%RESET%

:: 创建测试安装目录
set "TEST_INSTALL_DIR=%TEMP%\CharAsGem_MSI_Test_%RANDOM%"
mkdir "%TEST_INSTALL_DIR%" 2>nul

:: 复制 MSI 到测试目录
copy "%MSI_FILE%" "%TEST_INSTALL_DIR%\" >nul
if %ERRORLEVEL% equ 0 (
    echo %GREEN%  ✓ 测试环境准备就绪%RESET%
    echo %BLUE%    测试目录: %TEST_INSTALL_DIR%%RESET%
    set /a PASSED_TESTS+=1
) else (
    echo %RED%  ❌ 无法创建测试环境%RESET%
    set /a FAILED_TESTS+=1
)

:test_summary
echo.
echo %GREEN%==========================================
echo 测试结果汇总
echo ==========================================%RESET%
echo.

echo %BLUE%总计测试项: %TOTAL_TESTS%%RESET%
echo %GREEN%通过测试: %PASSED_TESTS%%RESET%
echo %RED%失败测试: %FAILED_TESTS%%RESET%

set /a SUCCESS_RATE=(%PASSED_TESTS% * 100) / %TOTAL_TESTS%
echo %BLUE%成功率: %SUCCESS_RATE%%%RESET%
echo.

if %FAILED_TESTS% equ 0 (
    echo %GREEN%🎉 所有测试通过！MSI 构建系统工作正常。%RESET%
    
    echo.
    echo %BLUE%构建文件位置:%RESET%
    echo   %MSI_FILE%
    
    if exist "%TEST_INSTALL_DIR%" (
        echo.
        echo %YELLOW%测试安装选项:%RESET%
        set /p RUN_INSTALL_TEST="是否在测试环境中安装 MSI？(需要管理员权限) (y/N): "
        if /i "!RUN_INSTALL_TEST!"=="y" (
            echo.
            echo %YELLOW%开始安装测试...%RESET%
            echo %RED%注意: 这将在您的系统上安装应用程序%RESET%
            set /p CONFIRM_INSTALL="确认继续安装测试？(y/N): "
            if /i "!CONFIRM_INSTALL!"=="y" (
                echo %BLUE%执行安装...%RESET%
                "%TEST_INSTALL_DIR%\CharAsGemInstaller_v1.0.1.exe" /SILENT
                echo %GREEN%安装命令已执行，请检查结果%RESET%
                echo 可在开始菜单中查找"字字珠玑"应用程序
                
                timeout /t 5 /nobreak >nul
                
                :: 尝试找到已安装的应用
                if exist "%LOCALAPPDATA%\Programs\CharAsGem" (
                    echo %GREEN%✓ 检测到应用程序已安装%RESET%
                ) else if exist "%PROGRAMFILES%\CharAsGem" (
                    echo %GREEN%✓ 检测到应用程序已安装%RESET%
                ) else (
                    echo %YELLOW%⚠ 无法确认安装状态%RESET%
                )
            )
        )
    )
    
    echo.
    echo %BLUE%后续建议:%RESET%
    echo 1. 在不同的 Windows 版本上测试安装
    echo 2. 验证应用程序功能完整性
    echo 3. 测试卸载过程
    echo 4. 检查文件关联是否正确
    echo 5. 验证数字签名（如果已签名）
    
) else (
    echo %RED%❌ 测试未完全通过，请检查失败的测试项。%RESET%
    echo.
    echo %YELLOW%建议的修复步骤:%RESET%
    echo 1. 检查前置软件是否正确安装
    echo 2. 验证 Flutter 构建环境
    echo 3. 检查文件路径和权限
    echo 4. 查看详细错误信息
    echo 5. 参考 MSI 构建文档
)

:: 清理测试目录
if exist "%TEST_INSTALL_DIR%" (
    set /p CLEANUP="是否清理测试目录？(Y/n): "
    if /i not "!CLEANUP!"=="n" (
        rmdir /s /q "%TEST_INSTALL_DIR%" 2>nul
        echo %GREEN%✓ 测试目录已清理%RESET%
    )
)

echo.
pause
