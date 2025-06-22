@echo off
echo ===== Applying ARB Mapping from YAML =====
echo.

:: Check if Python is installed
where python >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Python not found. Please install Python 3.6 or later.
    exit /b 1
)

:: Check if the YAML file exists
if not exist "arb_report\key_mapping.yaml" (
    echo Error: YAML mapping file not found.
    echo Please run generate_arb_mapping.bat first to create the mapping file.
    exit /b 1
)

:: Ask for confirmation
echo This will update ARB files and code references based on your YAML mapping.
echo Make sure you have committed or backed up your changes.
set /p CONFIRM=Are you sure you want to continue? (Y/N): 

if /i "%CONFIRM%" NEQ "Y" (
    echo Operation cancelled.
    exit /b 0
)

:: Run the apply script
python apply_arb_mapping.py

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Successfully applied YAML mapping to ARB files!
    echo Don't forget to run flutter gen-l10n to regenerate localization files.
) else (
    echo.
    echo ❌ Failed to apply YAML mapping.
)

echo.
echo Press any key to exit...
pause >nul
