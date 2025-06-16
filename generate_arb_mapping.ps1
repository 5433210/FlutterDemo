# PowerShell script to generate ARB mapping YAML

Write-Host "===== Generating ARB Mapping YAML =====" -ForegroundColor Cyan
Write-Host ""

# Check if Python is installed
$pythonInstalled = $false
try {
    $pythonVersion = python --version
    $pythonInstalled = $true
    Write-Host "Using $pythonVersion" -ForegroundColor Green
} catch {
    try {
        $pythonVersion = python3 --version
        $pythonInstalled = $true
        Write-Host "Using $pythonVersion" -ForegroundColor Green
    } catch {
        Write-Host "Error: Python not found. Please install Python 3.6 or later." -ForegroundColor Red
        exit 1
    }
}

# Check if the generator script exists
if (-not (Test-Path "generate_arb_mapping.py")) {
    Write-Host "Error: Script 'generate_arb_mapping.py' not found." -ForegroundColor Red
    exit 1
}

# Run the generator script
Write-Host "Running generator script..." -ForegroundColor Yellow
$startTime = Get-Date

if ($pythonInstalled) {
    try {
        python generate_arb_mapping.py
        $exitCode = $LASTEXITCODE
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Host ""
        Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
        
        if ($exitCode -eq 0) {
            Write-Host "✅ YAML mapping file generated successfully!" -ForegroundColor Green
            Write-Host "Edit the file arb_report\key_mapping.yaml to customize the key mappings." -ForegroundColor Yellow
            Write-Host "Then run apply_arb_mapping.ps1 to apply your changes." -ForegroundColor Yellow
        } else {
            Write-Host "❌ Failed to generate YAML mapping file." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error running the generator script: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Python is required but not found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
