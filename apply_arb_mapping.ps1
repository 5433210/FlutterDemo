# PowerShell script to apply ARB mapping from YAML

Write-Host "===== Applying ARB Mapping from YAML =====" -ForegroundColor Cyan
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

# Check if the apply script exists
if (-not (Test-Path "apply_arb_mapping.py")) {
    Write-Host "Error: Script 'apply_arb_mapping.py' not found." -ForegroundColor Red
    exit 1
}

# Check if the YAML file exists
if (-not (Test-Path "arb_report\key_mapping.yaml")) {
    Write-Host "Error: YAML mapping file not found." -ForegroundColor Red
    Write-Host "Please run generate_arb_mapping.ps1 first to create the mapping file." -ForegroundColor Yellow
    exit 1
}

# Ask for confirmation
Write-Host "This will update ARB files and code references based on your YAML mapping." -ForegroundColor Yellow
Write-Host "Make sure you have committed or backed up your changes." -ForegroundColor Yellow
$confirm = Read-Host "Are you sure you want to continue? (Y/N)"

if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

# Run the apply script
Write-Host "Applying YAML mapping..." -ForegroundColor Yellow
$startTime = Get-Date

if ($pythonInstalled) {
    try {
        python apply_arb_mapping.py
        $exitCode = $LASTEXITCODE
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Host ""
        Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
        
        if ($exitCode -eq 0) {
            Write-Host "✅ Successfully applied YAML mapping to ARB files!" -ForegroundColor Green
            Write-Host "Don't forget to run flutter gen-l10n to regenerate localization files." -ForegroundColor Yellow
        } else {
            Write-Host "❌ Failed to apply YAML mapping." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error running the apply script: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Python is required but not found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
