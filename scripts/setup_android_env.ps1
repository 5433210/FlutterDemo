# Android SDK环境变量配置脚本
# 以管理员身份运行PowerShell，然后执行此脚本

# Android SDK路径
$androidSdkPath = "C:\Users\wailik\AppData\Local\Android\Sdk"

# 设置ANDROID_HOME环境变量
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkPath, "Machine")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidSdkPath, "Machine")

# 获取当前系统PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

# 要添加的路径
$platformToolsPath = "$androidSdkPath\platform-tools"
$cmdlineToolsPath = "$androidSdkPath\cmdline-tools\latest\bin"

# 添加platform-tools到PATH
if ($currentPath -notlike "*$platformToolsPath*") {
    $updatedPath = $currentPath + ";" + $platformToolsPath
    [Environment]::SetEnvironmentVariable("Path", $updatedPath, "Machine")
    Write-Host "✅ 已添加 platform-tools 到PATH: $platformToolsPath" -ForegroundColor Green
} else {
    Write-Host "ℹ️ platform-tools 已存在于PATH中" -ForegroundColor Blue
}

# 添加cmdline-tools到PATH
if (Test-Path $cmdlineToolsPath) {
    if ($currentPath -notlike "*$cmdlineToolsPath*") {
        $updatedPath = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + $cmdlineToolsPath
        [Environment]::SetEnvironmentVariable("Path", $updatedPath, "Machine")
        Write-Host "✅ 已添加 cmdline-tools 到PATH: $cmdlineToolsPath" -ForegroundColor Green
    } else {
        Write-Host "ℹ️ cmdline-tools 已存在于PATH中" -ForegroundColor Blue
    }
}

Write-Host "✅ Android SDK环境变量配置完成" -ForegroundColor Green
Write-Host "⚠️ 请重启PowerShell/命令提示符使设置生效" -ForegroundColor Yellow

# 验证设置
Write-Host "`n🔍 验证环境变量..."
Write-Host "ANDROID_HOME: $([Environment]::GetEnvironmentVariable('ANDROID_HOME', 'Machine'))"
Write-Host "ANDROID_SDK_ROOT: $([Environment]::GetEnvironmentVariable('ANDROID_SDK_ROOT', 'Machine'))"

# 验证工具可用性
Write-Host "`n🔍 验证工具可用性..."
try {
    & "$platformToolsPath\adb.exe" version
    Write-Host "✅ ADB 可用" -ForegroundColor Green
} catch {
    Write-Host "❌ ADB 不可用，请重启后再试" -ForegroundColor Red
}
