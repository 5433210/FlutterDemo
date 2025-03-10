@echo off
setlocal enabledelayedexpansion

echo Checking test environment...
echo.

REM 1. Check Flutter installation
echo Checking Flutter installation...
flutter --version > nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter is not installed or not in PATH
    exit /b 1
) else (
    echo OK: Flutter is installed
)

REM 2. Check dependencies
echo Checking project dependencies...
flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies
    exit /b 1
) else (
    echo OK: Dependencies are installed
)

REM 3. Create test data directory
echo Creating test data directory...
if not exist "test\data" mkdir "test\data"
if errorlevel 1 (
    echo ERROR: Failed to create test data directory
    exit /b 1
) else (
    echo OK: Test data directory is ready
)

REM 4. Clean old test data
echo Cleaning old test data...
if exist "coverage" rd /s /q "coverage"
if exist "test\data\*" del /q "test\data\*"
if errorlevel 1 (
    echo ERROR: Failed to clean old test data
    exit /b 1
) else (
    echo OK: Old test data cleaned
)

REM 5. Check Dart compiler
echo Checking Dart compiler...
dart --version > nul 2>&1
if errorlevel 1 (
    echo ERROR: Dart compiler not found
    exit /b 1
) else (
    echo OK: Dart compiler is available
)

REM 6. Check SQLite (not required for Windows)
echo Note: Windows uses sqflite_common_ffi, no need for SQLite installation

REM 7. Final check
echo.
echo Environment check completed successfully
echo ========================================
echo Test environment is ready
echo - Flutter: Installed
echo - Dependencies: Updated
echo - Test directory: Created
echo - Old data: Cleaned
echo - Dart compiler: Available
echo ========================================
echo.
echo You can now run the tests using:
echo test\run_tests.bat
echo.

pause