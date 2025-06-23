# Windows SDK工具PATH配置脚本
# 以管理员身份运行PowerShell，然后执行此脚本

# 获取当前系统PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

# 要添加的路径
$newPath = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64"

# 检查路径是否已存在
if ($currentPath -notlike "*$newPath*") {
    # 添加新路径
    $updatedPath = $currentPath + ";" + $newPath
    [Environment]::SetEnvironmentVariable("Path", $updatedPath, "Machine")
    Write-Host "✅ 已添加 Windows SDK 工具到系统PATH: $newPath" -ForegroundColor Green
    Write-Host "⚠️ 请重启PowerShell/命令提示符使设置生效" -ForegroundColor Yellow
} else {
    Write-Host "ℹ️ Windows SDK 工具路径已存在于PATH中" -ForegroundColor Blue
}

# 验证工具是否可用
Write-Host "`n🔍 验证工具可用性..."
try {
    & signtool
    Write-Host "✅ SignTool 可用" -ForegroundColor Green
} catch {
    Write-Host "❌ SignTool 不可用" -ForegroundColor Red
}

try {
    & makeappx
    Write-Host "✅ MakeAppx 可用" -ForegroundColor Green
} catch {
    Write-Host "❌ MakeAppx 不可用" -ForegroundColor Red
}
