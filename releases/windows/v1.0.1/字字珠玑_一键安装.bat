@echo off
echo ===========================================
echo     字字珠玑 v1.0.1 自动安装程序
echo ===========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "CERT_FILE=%SCRIPT_DIR%CharAsGem.cer"
set "MSIX_FILE=%SCRIPT_DIR%CharAsGemInstaller_v1.0.1_NEW.msix"

echo 正在安装字字珠玑应用...
echo.

echo [1/3] 检查文件...
if not exist "%CERT_FILE%" (
    echo ✗ 错误: 证书文件不存在
    echo 请确保 CharAsGem.cer 文件在同一目录下
    pause
    exit /b 1
)

if not exist "%MSIX_FILE%" (
    echo ✗ 错误: 安装包文件不存在
    echo 请确保 CharAsGemInstaller_v1.0.1_NEW.msix 文件在同一目录下
    pause
    exit /b 1
)

echo ✓ 安装文件检查完成

echo [2/3] 安装证书...
echo 正在打开证书安装对话框...
echo 请在弹出的对话框中：
echo   1. 点击"安装证书"
echo   2. 选择"本地计算机"
echo   3. 选择"将所有的证书都放入下列存储"
echo   4. 浏览选择"受信任的根证书颁发机构"
echo   5. 点击"确定"完成安装
echo.

start /wait "" "%CERT_FILE%"

echo 证书安装完成（如果您按照上述步骤操作）

echo [3/3] 安装应用...
echo 正在打开应用安装程序...
echo.

start "" "%MSIX_FILE%"

echo ===========================================
echo 安装程序已启动
echo ===========================================
echo.
echo 如果遇到0x800B0109错误，请：
echo 1. 以管理员身份运行命令提示符
echo 2. 执行: certutil -addstore -f "ROOT" "%CERT_FILE%"
echo 3. 重启计算机后重新安装
echo.
echo 感谢使用字字珠玑！
pause
