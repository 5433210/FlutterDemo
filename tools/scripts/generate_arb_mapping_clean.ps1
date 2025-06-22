# ARB优化脚本 PowerShell版（无行内注释版）
Write-Host "正在运行ARB优化脚本（无行内注释版）..." -ForegroundColor Cyan

try {
    python enhanced_arb_mapping.py
    
    Write-Host "`n生成完成！" -ForegroundColor Green
    Write-Host "请检查 arb_report/key_mapping.yaml 文件" -ForegroundColor Green
    Write-Host "编辑完成后，使用 apply_arb_mapping.ps1 应用您的更改" -ForegroundColor Green
} catch {
    Write-Host "`n执行脚本时出错:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "`n按任意键继续..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
