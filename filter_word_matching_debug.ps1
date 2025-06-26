# 词匹配模式调试日志过滤脚本 (PowerShell版本)
# 使用方法: flutter run -d windows --debug 2>&1 | powershell -File filter_word_matching_debug.ps1

Write-Host "=== 词匹配模式调试日志过滤器 ===" -ForegroundColor Green
Write-Host "正在监听包含 [WORD_MATCHING_DEBUG] 的日志..." -ForegroundColor Yellow
Write-Host "==========================================="

while ($line = Read-Host) {
    if ($line -match "\[WORD_MATCHING_DEBUG\]") {
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] $line" -ForegroundColor Cyan
    }
}
