@echo off
echo ===== ARB Key Mapping Tools =====
echo.

if "%1"=="create" goto create
if "%1"=="apply" goto apply
if "%1"=="help" goto help
if "%1"=="" goto menu

:menu
echo Please select an option:
echo 1. Create YAML mapping from current key_mapping.json
echo 2. Apply edited YAML mapping to update ARB files and code
echo 3. Help
echo 4. Exit

set /p choice=Enter your choice (1-4): 

if "%choice%"=="1" goto create
if "%choice%"=="2" goto apply
if "%choice%"=="3" goto help
if "%choice%"=="4" goto end
goto menu

:create
echo.
echo Creating YAML mapping from key_mapping.json...
python create_yaml_mapping.py
echo.
echo Next steps:
echo 1. Edit the YAML file at arb_report\key_mapping.yaml
echo 2. Run this script again with "apply" to update ARB files
echo.
goto end

:apply
echo.
echo Applying YAML mapping to update ARB files and code...
python apply_yaml_mapping.py
echo.
goto end

:help
echo.
echo ARB Key Mapping Tools
echo ---------------------
echo.
echo This tool helps you manage ARB key mappings in a more intuitive way.
echo.
echo Commands:
echo   arb_key_mapping.bat create - Create YAML mapping from key_mapping.json
echo   arb_key_mapping.bat apply  - Apply edited YAML mapping to update ARB files
echo   arb_key_mapping.bat help   - Show this help message
echo.
echo Workflow:
echo 1. Run "create" to generate a YAML file with all keys and values
echo 2. Edit the YAML file at arb_report\key_mapping.yaml
echo 3. Run "apply" to update ARB files and code references
echo.
goto end

:end
echo.
echo Press any key to exit...
pause >nul
