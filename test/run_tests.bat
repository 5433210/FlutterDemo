@echo off
setlocal EnableDelayedExpansion

REM 记录开始时间
set start_time=%time%

REM 创建必要的目录
mkdir test\reports 2>nul
mkdir coverage\reports 2>nul
mkdir test\benchmark\results 2>nul

echo [33m开始运行测试套件...[0m

REM 1. 运行前检查
echo.
echo [33m1. 运行前检查[0m
dart test/run_pre_check.dart
if errorlevel 1 (
    echo [31m前置检查失败，终止测试[0m
    exit /b 1
)

REM 2. 运行单元测试
echo.
echo [33m2. 运行单元测试[0m
dart test --coverage=coverage --reporter=json test/utils/alerts/ > test/reports/unit_test_results.json
if errorlevel 1 (
    echo [31m单元测试失败[0m
    exit /b 1
)

REM 3. 生成覆盖率报告
echo.
echo [33m3. 生成覆盖率报告[0m
dart run coverage:format_coverage ^
    --lcov ^
    --in=coverage ^
    --out=coverage/lcov.info ^
    --packages=.packages ^
    --report-on=lib

REM 4. 检查覆盖率
echo.
echo [33m4. 检查覆盖率[0m
dart run test/coverage/check_coverage.dart
if errorlevel 1 (
    echo [31m覆盖率不足[0m
    exit /b 1
)

REM 5. 运行性能基准测试
echo.
echo [33m5. 运行性能基准测试[0m
dart run test/utils/alerts/alert_benchmark_test.dart
if errorlevel 1 (
    echo [31m性能测试失败[0m
    exit /b 1
)

REM 6. 运行集成测试
echo.
echo [33m6. 运行集成测试[0m
dart test test/integration/
if errorlevel 1 (
    echo [31m集成测试失败[0m
    exit /b 1
)

REM 7. 生成测试报告
echo.
echo [33m7. 生成测试报告[0m
dart run test/integration/generate_report.dart

REM 计算总耗时
set end_time=%time%
set options="tokens=1-4 delims=:.,"
for /f %options% %%a in ("%start_time%") do set start_h=%%a&set /a start_m=100%%b %% 100&set /a start_s=100%%c %% 100
for /f %options% %%a in ("%end_time%") do set end_h=%%a&set /a end_m=100%%b %% 100&set /a end_s=100%%c %% 100

set /a hours=%end_h%-%start_h%
set /a mins=%end_m%-%start_m%
set /a secs=%end_s%-%start_s%
if %secs% lss 0 set /a mins = %mins% - 1 & set /a secs = 60 + %secs%
if %mins% lss 0 set /a hours = %hours% - 1 & set /a mins = 60 + %mins%
if %hours% lss 0 set /a hours = 24 + %hours%

REM 输出总结
echo.
echo [32m测试完成![0m
echo 总耗时: %hours%时%mins%分%secs%秒
echo 测试报告位置: test\reports\
echo 覆盖率报告: coverage\reports\
echo 基准测试结果: test\benchmark\results\

REM 检查是否有失败的测试
findstr /C:"\"failed\":true" test\reports\*.json >nul
if errorlevel 1 (
    echo [32m所有测试通过[0m
    exit /b 0
) else (
    echo [31m存在失败的测试用例[0m
    exit /b 1
)