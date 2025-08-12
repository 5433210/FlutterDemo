# Android 模拟器调试环境清理脚本 (PowerShell 版本)
param(
    [string]$PackageName = "com.example.demo",
    [switch]$Force = $false,
    [switch]$SkipReboot = $false
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Android 模拟器调试环境清理工具" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# 检查 ADB 是否可用
function Test-ADBAvailable {
    # 首先尝试系统 PATH 中的 ADB
    try {
        $null = & adb version 2>$null
        return $true
    }
    catch {
        # 尝试默认的 Android SDK 位置
        $defaultAdbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
        if (Test-Path $defaultAdbPath) {
            $script:adbPath = $defaultAdbPath
            Write-Host "使用本地 Android SDK 中的 ADB: $defaultAdbPath" -ForegroundColor Yellow
            return $true
        }
        
        Write-Host "错误: ADB 未找到" -ForegroundColor Red
        Write-Host "请确保 Android SDK platform-tools 已安装并添加到 PATH 中" -ForegroundColor Red
        Write-Host "或者安装位置为: $defaultAdbPath" -ForegroundColor Red
        return $false
    }
}

# 检查设备连接
function Test-DeviceConnected {
    $adbCmd = if ($script:adbPath) { $script:adbPath } else { "adb" }
    $devices = & $adbCmd devices 2>$null | Select-String -Pattern "device$"
    if ($devices.Count -eq 0) {
        Write-Host "警告: 没有检测到连接的 Android 设备/模拟器" -ForegroundColor Yellow
        return $false
    }
    Write-Host "检测到 $($devices.Count) 个设备" -ForegroundColor Green
    return $true
}

# 主清理流程
function Start-CleanProcess {
    # 初始化 ADB 路径变量
    $script:adbPath = $null
    
    Write-Host "`n[1/7] 检查 ADB 工具..." -ForegroundColor Yellow
    if (-not (Test-ADBAvailable)) {
        return
    }

    Write-Host "[2/7] 检查设备连接..." -ForegroundColor Yellow
    $deviceConnected = Test-DeviceConnected

    if ($deviceConnected) {
        $adbCmd = if ($script:adbPath) { $script:adbPath } else { "adb" }
        
        Write-Host "[3/7] 清理应用数据..." -ForegroundColor Yellow
        try {
            & $adbCmd shell pm clear $PackageName 2>$null
            Write-Host "✅ 应用数据清理完成" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️ 应用数据清理失败（可能应用未安装）" -ForegroundColor Yellow
        }

        Write-Host "[4/7] 卸载调试版本..." -ForegroundColor Yellow
        try {
            & $adbCmd uninstall $PackageName 2>$null
            Write-Host "✅ 应用卸载完成" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️ 应用卸载失败（可能应用未安装）" -ForegroundColor Yellow
        }

        Write-Host "[5/7] 清理模拟器临时文件..." -ForegroundColor Yellow
        try {
            & $adbCmd shell rm -rf /data/local/tmp/* 2>$null
            & $adbCmd shell rm -rf /sdcard/Android/data/$PackageName 2>$null
            Write-Host "✅ 临时文件清理完成" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️ 部分临时文件清理失败" -ForegroundColor Yellow
        }
    }

    Write-Host "[6/7] 清理 Flutter 项目..." -ForegroundColor Yellow
    try {
        & flutter clean | Out-Null
        & flutter pub get | Out-Null
        Write-Host "✅ Flutter 项目清理完成" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Flutter 项目清理失败" -ForegroundColor Red
    }

    Write-Host "[7/7] 清理 Android Gradle 缓存..." -ForegroundColor Yellow
    try {
        Push-Location android
        & ./gradlew clean | Out-Null
        Pop-Location
        Write-Host "✅ Gradle 缓存清理完成" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Gradle 缓存清理失败" -ForegroundColor Red
        Pop-Location
    }

    # 可选的模拟器重启
    if ($deviceConnected -and -not $SkipReboot) {
        Write-Host "`n是否重启模拟器以完成清理？(y/n): " -ForegroundColor Cyan -NoNewline
        if ($Force -or (Read-Host) -eq 'y') {
            Write-Host "正在重启模拟器..." -ForegroundColor Yellow
            $adbCmd = if ($script:adbPath) { $script:adbPath } else { "adb" }
            & $adbCmd reboot
            Write-Host "✅ 模拟器重启中..." -ForegroundColor Green
        }
    }

    Write-Host "`n✅ 清理流程完成！" -ForegroundColor Green
    Write-Host "调试环境已完全清理，可以重新部署应用" -ForegroundColor Cyan
}

# 执行清理
Start-CleanProcess
