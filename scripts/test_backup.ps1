# 备份测试与监控脚本 (PowerShell版本)

Write-Host "=== 备份测试与监控脚本 ===" -ForegroundColor Green
Write-Host "此脚本将帮助您测试备份功能并监控过程" -ForegroundColor Yellow
Write-Host ""

# 检查是否在正确的目录
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ 请在 Flutter 项目根目录运行此脚本" -ForegroundColor Red
    exit 1
}

Write-Host "🔧 准备环境..." -ForegroundColor Cyan

# 创建日志目录
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

Write-Host "📋 选择操作:" -ForegroundColor Yellow
Write-Host "1) 运行备份诊断"
Write-Host "2) 测试备份功能 (需要应用运行)"
Write-Host "3) 监控备份日志"
Write-Host "4) 查看最近的备份日志"
Write-Host "5) 查看存储目录分析"

$choice = Read-Host "请选择 (1-5)"

switch ($choice) {
    "1" {
        Write-Host "🔍 运行备份诊断..." -ForegroundColor Cyan
        dart run scripts/diagnose_backup_simple.dart
    }
    "2" {
        Write-Host "⚠️ 请确保应用正在运行，然后在应用中手动触发备份" -ForegroundColor Yellow
        Write-Host "💡 建议同时打开另一个 PowerShell 运行: .\scripts\test_backup.ps1 选择3" -ForegroundColor Blue
        Write-Host ""
        Read-Host "准备就绪后按 Enter 继续监控..."
        dart run scripts/monitor_backup.dart
    }
    "3" {
        Write-Host "📊 开始监控备份日志..." -ForegroundColor Cyan
        dart run scripts/monitor_backup.dart
    }
    "4" {
        Write-Host "📄 最近的备份相关日志:" -ForegroundColor Cyan
        if (Test-Path "logs/app.log") {
            Get-Content "logs/app.log" | Select-String -Pattern "backup|备份|复制" | Select-Object -Last 20
        } else {
            Write-Host "❌ 未找到日志文件" -ForegroundColor Red
        }
    }
    "5" {
        Write-Host "🗂️ 分析存储目录结构..." -ForegroundColor Cyan
        $appSupportPath = [System.Environment]::GetFolderPath('ApplicationData')
        $charasgemPath = Join-Path $appSupportPath "charasgem\storage"
        
        Write-Host "检查路径: $charasgemPath" -ForegroundColor Gray
        
        if (Test-Path $charasgemPath) {
            Write-Host "✅ 找到存储目录" -ForegroundColor Green
            
            $subdirs = @("characters", "database", "practices", "library", "cache", "temp", "backups")
            
            foreach ($subdir in $subdirs) {
                $dirPath = Join-Path $charasgemPath $subdir
                if (Test-Path $dirPath) {
                    $fileCount = (Get-ChildItem -Path $dirPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
                    $totalSize = (Get-ChildItem -Path $dirPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    $sizeMB = [math]::Round($totalSize / 1MB, 2)
                    
                    Write-Host "📁 $subdir : $fileCount 文件, $sizeMB MB" -ForegroundColor White
                } else {
                    Write-Host "📂 $subdir : 不存在" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host "❌ 未找到存储目录: $charasgemPath" -ForegroundColor Red
        }
    }
    default {
        Write-Host "❌ 无效选择" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "✅ 操作完成" -ForegroundColor Green
Read-Host "按 Enter 退出"
