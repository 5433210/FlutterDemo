@echo off
chcp 65001 >nul
echo ==========================================
echo 字字珠玑 MSI 构建环境快速检查
echo ==========================================
echo.

echo 检查 Inno Setup...
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    echo ✓ Inno Setup 6 已安装
) else (
    echo ❌ Inno Setup 6 未找到
    echo 请从 https://jrsoftware.org/isdl.php 下载安装
)

echo.
echo 检查 Flutter 构建...
if exist "build\windows\x64\runner\Release\charasgem.exe" (
    echo ✓ Flutter Windows 构建存在
) else (
    echo ❌ Flutter Windows 构建不存在
    echo 请运行: flutter build windows --release
)

echo.
echo 检查配置文件...
if exist "package\windows\msi\setup.iss" (
    echo ✓ setup.iss 配置文件存在
) else (
    echo ❌ setup.iss 配置文件缺失
)

echo.
echo 检查输出目录...
if not exist "releases\windows\v1.0.1" mkdir "releases\windows\v1.0.1"
echo ✓ 输出目录已准备

echo.
echo 环境检查完成！
echo 如果所有项目都显示 ✓，您可以运行：
echo   package\windows\msi\Build_MSI_Package.bat
echo.
pause
