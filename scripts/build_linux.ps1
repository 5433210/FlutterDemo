# WSL Flutter Linux Build Script (PowerShell)
param(
    [Parameter(Position=0)]
    [ValidateSet("setup", "build", "help")]
    [string]$Action = ""
)

# Set console encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Test-WSL {
    Write-Info "Checking WSL environment..."
    
    # Check if WSL is available
    try {
        $wslList = wsl --list --quiet 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "WSL not installed or unavailable"
            Write-Host "Please install WSL and Linux distribution first" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Error-Custom "WSL command execution failed"
        return $false
    }
    
    # Check if Ubuntu is available
    try {
        wsl -d Ubuntu -e echo "WSL Ubuntu available" 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Ubuntu WSL unavailable"
            Write-Host "Please ensure Ubuntu WSL is installed and running" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Error-Custom "Cannot connect to Ubuntu WSL"
        return $false
    }
    
    Write-Success "WSL environment check passed"
    return $true
}

function Set-ScriptPermissions {
    Write-Info "Setting script permissions..."
    
    $projectPath = "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo"
    
    try {
        wsl -d Ubuntu -e chmod +x "$projectPath/scripts/setup_ubuntu_wsl_flutter.sh"
        wsl -d Ubuntu -e chmod +x "$projectPath/scripts/build_ubuntu_wsl.sh"
        Write-Success "Script permissions set successfully"
        return $true
    }
    catch {
        Write-Error-Custom "Failed to set script permissions"
        return $false
    }
}

function Invoke-WSLSetup {
    Write-Info "Starting WSL Flutter environment setup..."
    
    $projectPath = "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo"
    $setupScript = "$projectPath/scripts/setup_ubuntu_wsl_flutter.sh"
    
    try {
        wsl -d Ubuntu -e bash $setupScript
        if ($LASTEXITCODE -eq 0) {
            Write-Success "WSL Flutter environment setup completed!"
            Write-Host "You can now run build command" -ForegroundColor Cyan
            return $true
        }
        else {
            Write-Error-Custom "WSL Flutter environment setup failed"
            return $false
        }
    }
    catch {
        Write-Error-Custom "Error occurred while executing setup script"
        return $false
    }
}

function Invoke-WSLBuild {
    Write-Info "Starting Linux version build..."
    
    $projectPath = "/mnt/c/Users/wailik/Documents/Code/Flutter/demo/demo"
    $buildScript = "$projectPath/scripts/build_ubuntu_wsl.sh"
    
    try {
        wsl -d Ubuntu -e bash $buildScript
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Linux version build completed!"
            Write-Info "Build artifacts location: build\linux\x64\release\bundle\"
            
            # Show build artifact info
            if (Test-Path "build\linux\x64\release\bundle") {
                $buildSize = (Get-ChildItem "build\linux\x64\release\bundle" -Recurse | Measure-Object -Property Length -Sum).Sum
                $buildSizeMB = [math]::Round($buildSize / 1MB, 2)
                Write-Info "Build size: $buildSizeMB MB"
            }
            return $true
        }
        else {
            Write-Error-Custom "Linux version build failed"
            return $false
        }
    }
    catch {
        Write-Error-Custom "Error occurred while executing build script"
        return $false
    }
}

function Show-Help {
    Write-Host @"
WSL Flutter Linux Build Tool

Usage:
    .\scripts\build_linux.ps1 [action]

Available actions:
    setup   - Setup WSL Flutter environment (first time use)
    build   - Build Linux version (requires environment setup first)
    help    - Show this help information

Examples:
    .\scripts\build_linux.ps1 setup
    .\scripts\build_linux.ps1 build

If no action is specified, interactive menu will be displayed.
"@ -ForegroundColor White
}

function Show-Menu {
    Write-Host ""
    Write-Host "=== WSL Flutter Linux Build Tool ===" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Available options:" -ForegroundColor White
    Write-Host "1. Setup WSL Flutter environment (first time use)" -ForegroundColor Cyan
    Write-Host "2. Build Linux version (requires environment setup first)" -ForegroundColor Cyan  
    Write-Host "3. Show help information" -ForegroundColor Cyan
    Write-Host "4. Exit" -ForegroundColor Cyan
    Write-Host ""
    
    do {
        $choice = Read-Host "Please select operation (1-4)"
        
        switch ($choice) {
            "1" {
                if (Test-WSL -and (Set-ScriptPermissions)) {
                    Invoke-WSLSetup
                }
                break
            }
            "2" {
                if (Test-WSL -and (Set-ScriptPermissions)) {
                    Invoke-WSLBuild
                }
                break
            }
            "3" {
                Show-Help
                break
            }
            "4" {
                Write-Host "Goodbye!" -ForegroundColor Green
                return
            }
            default {
                Write-Warning-Custom "Invalid selection, please enter 1-4"
            }
        }
        
        if ($choice -in @("1", "2", "3")) {
            Write-Host ""
            Read-Host "Press Enter to continue"
            Show-Menu
            return
        }
    } while ($true)
}

# Main program logic
Write-Host "🐧 WSL Flutter Linux Build Tool" -ForegroundColor Magenta

# Execute action based on parameter
switch ($Action.ToLower()) {
    "setup" {
        if (Test-WSL -and (Set-ScriptPermissions)) {
            Invoke-WSLSetup
        }
    }
    "build" {
        if (Test-WSL -and (Set-ScriptPermissions)) {
            Invoke-WSLBuild
        }
    }
    "help" {
        Show-Help
    }
    default {
        Show-Menu
    }
} 