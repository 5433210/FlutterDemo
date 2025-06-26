# 过滤NA修复调试日志的PowerShell脚本

Write-Host "开始监听NA修复调试日志..." -ForegroundColor Green
Write-Host "请在应用中测试输入'na'来验证修复效果" -ForegroundColor Yellow
Write-Host "按Ctrl+C停止监听" -ForegroundColor Yellow
Write-Host "==========================" -ForegroundColor Cyan

# 使用adb logcat过滤日志
& adb logcat | Select-String "\[NA_FIX_DEBUG\]"
