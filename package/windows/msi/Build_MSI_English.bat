@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==========================================
echo CharAsGem MSI Compatibility Package Build
echo ==========================================
echo.

:: Set colors
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "GREEN=%ESC%[32m"
set "RED=%ESC%[31m"
set "YELLOW=%ESC%[33m"
set "BLUE=%ESC%[36m"
set "RESET=%ESC%[0m"

:: Get project root directory and change to it
set "PROJECT_ROOT=%~dp0..\..\..\"
pushd "%PROJECT_ROOT%"
set "PROJECT_ROOT=%cd%"

echo %BLUE%Current working directory: %PROJECT_ROOT%%RESET%

:: Set paths
set "MSI_DIR=%PROJECT_ROOT%\package\windows\msi"
set "INNO_SETUP_DIR=C:\Program Files (x86)\Inno Setup 6"
set "COMPAT_RELEASE_DIR=%PROJECT_ROOT%\releases\windows\v1.0.1\compatibility"

:: Check and create output directory
if not exist "%COMPAT_RELEASE_DIR%" mkdir "%COMPAT_RELEASE_DIR%"

:: Check Inno Setup
if not exist "%INNO_SETUP_DIR%\ISCC.exe" (
    echo %RED%Error: Inno Setup not found%RESET%
    pause
    popd
    exit /b 1
)

:: Switch to MSI directory (important for relative paths)
cd /d "%MSI_DIR%"
echo %BLUE%Current directory: %CD%%RESET%

echo %YELLOW%Starting MSI compatibility package compilation...%RESET%

:: Compile using English version
"%INNO_SETUP_DIR%\ISCC.exe" "setup_compatibility.iss"

if !errorlevel! neq 0 (
    echo %RED%MSI compilation failed%RESET%
    pause
    popd
    exit /b 1
)

:: Check output file
set "OUTPUT_FILE=%COMPAT_RELEASE_DIR%\CharAsGemInstaller_Legacy_v1.0.1.exe"
if exist "%OUTPUT_FILE%" (
    echo %GREEN%✓ MSI package generated successfully: %OUTPUT_FILE%%RESET%
    dir "%OUTPUT_FILE%" | findstr "CharAsGemInstaller_Legacy"
) else (
    echo %RED%✗ MSI package not found%RESET%
    echo Expected location: %OUTPUT_FILE%
    echo Checking other possible locations...
    dir "%MSI_DIR%\*.exe" 2>nul
    if exist "%MSI_DIR%\CharAsGemInstaller_Legacy_v1.0.1.exe" (
        echo %YELLOW%Found file in MSI directory, moving...%RESET%
        move "%MSI_DIR%\CharAsGemInstaller_Legacy_v1.0.1.exe" "%OUTPUT_FILE%"
        if exist "%OUTPUT_FILE%" (
            echo %GREEN%✓ File moved successfully%RESET%
        )
    )
)

:: Copy certificate file
if exist "%PROJECT_ROOT%\package\windows\msix\CharAsGem.cer" (
    copy "%PROJECT_ROOT%\package\windows\msix\CharAsGem.cer" "%COMPAT_RELEASE_DIR%\" >nul
    echo %GREEN%✓ Certificate file copied%RESET%
)

:: Generate installation instructions (English)
echo Creating installation instructions...
(
echo CharAsGem - Windows Compatibility Package v1.0.1
echo ================================================
echo.
echo System Requirements:
echo - Windows 7 SP1 and above
echo - Windows 8/8.1/10/11
echo.
echo Installation Steps:
echo 1. Double-click CharAsGemInstaller_Legacy_v1.0.1.exe to start installation
echo 2. If security warning appears, click "More info" then "Run anyway"
echo 3. Follow the installation wizard to complete
echo.
echo Certificate Installation (Optional):
echo 1. Double-click CharAsGem.cer certificate file
echo 2. Click "Install Certificate"
echo 3. Select "Local Computer"
echo 4. Place certificate in "Trusted Root Certification Authorities"
echo.
echo Notes:
echo - This is a compatibility version for older Windows systems
echo - If you are using Windows 10/11, MSIX version is recommended
echo.
echo Technical Support: CharAsGem Development Team
) > "%COMPAT_RELEASE_DIR%\Installation_Instructions.txt"

:: Generate system compatibility test script (English)
(
echo @echo off
echo chcp 65001 ^>nul
echo echo =====================
echo echo System Compatibility Check
echo echo =====================
echo echo.
echo ver
echo echo.
echo echo Checking .NET Framework...
echo reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release 2^>nul ^|^| echo .NET Framework 4.0+ not installed
echo echo.
echo echo Checking Visual C++ Runtime...
echo dir "C:\Windows\System32\msvcp140.dll" 2^>nul ^&^& echo ✓ VC++ 2015-2022 installed ^|^| echo ✗ May need to install VC++ Runtime
echo echo.
echo echo Checking system architecture...
echo if "%%PROCESSOR_ARCHITECTURE%%"=="AMD64" ^( echo ✓ 64-bit system ^) else ^( echo ⚠ 32-bit system, compatibility issues may occur ^)
echo echo.
echo pause
) > "%COMPAT_RELEASE_DIR%\Test_System_Compatibility.bat"

:: Generate build report (English)
(
echo # CharAsGem Windows Compatibility Package Build Report
echo.
echo ## Build Information
echo - Build Time: %date% %time%
echo - Version: v1.0.1
echo - Package Type: MSI ^(Inno Setup^)
echo - Target Systems: Windows 7/8/10/11
echo - Installation Flow: Streamlined ^(no info pages^)
echo.
echo ## File List
echo - CharAsGemInstaller_Legacy_v1.0.1.exe ^(Installation Package^)
echo - CharAsGem.cer ^(Self-signed Certificate^)
echo - Installation_Instructions.txt ^(Installation Guide^)
echo - Test_System_Compatibility.bat ^(System Check Tool^)
echo.
echo ## Installation Experience
echo - License agreement page only
echo - No README/info page during installation
echo - Streamlined wizard experience
echo - Quick installation process
echo.
echo ## Compatibility Notes
echo - Minimum System Requirement: Windows 7 SP1
echo - Recommended System: Windows 10/11
echo - Architecture Support: x64
echo.
echo ## Installation Method
echo 1. Download compatibility package ^(this directory^)
echo 2. Run installation program
echo 3. Accept license agreement
echo 4. Choose installation options
echo 5. Complete installation
echo.
echo ## Technical Details
echo - Packaging Tool: Inno Setup 6.x
echo - Signing: Self-signed Certificate
echo - Compression: Standard Compression
echo - Info Pages: Disabled for streamlined experience
) > "%COMPAT_RELEASE_DIR%\Build_Report.md"

echo.
echo %GREEN%==========================================
echo Compatibility Package Build Complete!
echo ==========================================%RESET%
echo.
echo %BLUE%Output Directory: %COMPAT_RELEASE_DIR%%RESET%
echo.
echo Generated Files:
if exist "%OUTPUT_FILE%" echo %GREEN%✓ CharAsGemInstaller_Legacy_v1.0.1.exe%RESET%
if exist "%COMPAT_RELEASE_DIR%\CharAsGem.cer" echo %GREEN%✓ CharAsGem.cer%RESET%
if exist "%COMPAT_RELEASE_DIR%\Installation_Instructions.txt" echo %GREEN%✓ Installation_Instructions.txt%RESET%
if exist "%COMPAT_RELEASE_DIR%\Test_System_Compatibility.bat" echo %GREEN%✓ Test_System_Compatibility.bat%RESET%
if exist "%COMPAT_RELEASE_DIR%\Build_Report.md" echo %GREEN%✓ Build_Report.md%RESET%

echo.
pause
popd
