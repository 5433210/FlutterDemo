@echo off
echo ===== Generating ARB Mapping YAML =====
echo.

:: Check if Python is installed
where python >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Python not found. Please install Python 3.6 or later.
    exit /b 1
)

:: Run the generator script
python generate_arb_mapping.py

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ YAML mapping file generated successfully!
    echo Edit the file arb_report\key_mapping.yaml to customize the key mappings.
    echo Then run apply_arb_mapping.bat to apply your changes.
) else (
    echo.
    echo ❌ Failed to generate YAML mapping file.
)

echo.
echo Press any key to exit...
pause >nul
