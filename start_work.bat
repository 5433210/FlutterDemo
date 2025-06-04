@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM M3Canvas 性能优化项目启动脚本 (Windows版)
REM 使用方法: start_work.bat [task_number]

echo 🚀 M3Canvas 性能优化项目启动
echo ================================

REM 检查参数
set TASK_NUMBER=%1
if "%TASK_NUMBER%"=="" (
    echo ❌ 请指定任务编号，例如: start_work.bat 1.1
    echo.
    echo 📋 可用任务:
    echo   1.1 - 元素级RepaintBoundary优化
    echo   1.2 - 拖拽状态分离系统
    echo   1.3 - 性能监控系统
    echo   2.1 - 元素缓存管理器
    echo   2.2 - 视口优化系统
    pause
    exit /b 1
)

echo 🎯 启动任务: %TASK_NUMBER%
echo.

REM 1. 环境检查
echo 🔍 环境检查...

REM 检查Flutter
flutter --version > nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter未安装或未在PATH中
    pause
    exit /b 1
)

for /f "delims=" %%i in ('flutter --version ^| findstr /c:"Flutter"') do set FLUTTER_VERSION=%%i
echo ✅ Flutter版本: %FLUTTER_VERSION%

REM 检查项目目录
if not exist "pubspec.yaml" (
    echo ❌ 不在Flutter项目根目录
    pause
    exit /b 1
)

echo ✅ 项目目录正确

REM 2. 代码状态检查
echo.
echo 📂 代码状态检查...

REM Git状态检查
git status --porcelain > temp_git_status.txt 2>nul
if errorlevel 1 (
    echo ⚠️  Git未初始化或不在Git仓库中
) else (
    set /p GIT_STATUS=<temp_git_status.txt
    if not "!GIT_STATUS!"=="" (
        echo ⚠️  有未提交的变更:
        git status --short
        echo.
        set /p CONTINUE="是否继续？ (y/N): "
        if /i not "!CONTINUE!"=="y" (
            del temp_git_status.txt 2>nul
            exit /b 1
        )
    ) else (
        echo ✅ Git状态清洁
    )
    
    REM 当前分支
    for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set CURRENT_BRANCH=%%i
    echo ✅ 当前分支: !CURRENT_BRANCH!
)
del temp_git_status.txt 2>nul

REM 3. 依赖包检查
echo.
echo 📦 依赖包检查...
flutter pub get > nul 2>&1
echo ✅ 依赖包更新完成

REM 4. 编译检查
echo.
echo 🔨 编译检查...
flutter analyze --no-fatal-infos > nul 2>&1
if errorlevel 1 (
    echo ⚠️  代码分析发现问题:
    flutter analyze --no-fatal-infos
    echo.
    set /p CONTINUE="是否继续？ (y/N): "
    if /i not "!CONTINUE!"=="y" (
        exit /b 1
    )
) else (
    echo ✅ 代码分析通过
)

REM 5. 基线数据收集
echo.
echo 📊 收集基线数据...

REM 创建基线数据目录
if not exist "docs\performance_data" mkdir "docs\performance_data"

REM 获取当前时间戳
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "timestamp=%YYYY%%MM%%DD%_%HH%%Min%%Sec%"

set BASELINE_FILE=docs\performance_data\baseline_%timestamp%.md

REM 获取Git提交信息
for /f "delims=" %%i in ('git rev-parse --short HEAD 2^>nul') do set GIT_COMMIT=%%i
if "%GIT_COMMIT%"=="" set GIT_COMMIT=未知

(
echo # 性能基线数据
echo.
echo **采集时间**: %YYYY%-%MM%-%DD% %HH%:%Min%:%Sec%
echo **任务编号**: %TASK_NUMBER%
echo **Git提交**: %GIT_COMMIT%
echo **Flutter版本**: %FLUTTER_VERSION%
echo.
echo ## 设备信息
echo - **设备**: [待填写]
echo - **系统版本**: [待填写]
echo - **内存**: [待填写]
echo.
echo ## 性能数据
echo ### 当前FPS
echo - **拖拽操作**: [待测量] fps
echo - **缩放操作**: [待测量] fps
echo - **旋转操作**: [待测量] fps
echo - **选择操作**: [待测量] fps
echo.
echo ### 内存使用
echo - **初始内存**: [待测量] MB
echo - **操作后内存**: [待测量] MB
echo - **峰值内存**: [待测量] MB
echo.
echo ### 响应时间
echo - **点击响应**: [待测量] ms
echo - **拖拽开始**: [待测量] ms
echo - **属性更新**: [待测量] ms
echo.
echo ## 测试步骤
echo 1. 启动应用到编辑页面
echo 2. 执行标准操作序列
echo 3. 记录各项性能指标
echo 4. 注意观察卡顿现象
echo.
echo ## 备注
echo [记录任何特殊现象或问题]
) > "%BASELINE_FILE%"

echo ✅ 基线数据文件创建: %BASELINE_FILE%

REM 6. 任务相关文件检查
echo.
echo 📁 任务相关文件检查...

if "%TASK_NUMBER%"=="1.1" (
    echo 🎯 任务1.1: 元素级RepaintBoundary优化
    set FILES=lib\presentation\pages\practices\widgets\content_render_layer.dart lib\presentation\pages\practices\widgets\m3_practice_edit_canvas.dart
) else if "%TASK_NUMBER%"=="1.2" (
    echo 🎯 任务1.2: 拖拽状态分离系统
    set FILES=lib\presentation\widgets\practice\practice_edit_controller.dart lib\presentation\pages\practices\widgets\m3_practice_edit_canvas.dart
    
    REM 创建新文件占位符
    if not exist "lib\presentation\widgets\practice" mkdir "lib\presentation\widgets\practice"
    if not exist "lib\presentation\widgets\practice\drag_state_manager.dart" (
        echo // TODO: 实现DragStateManager > "lib\presentation\widgets\practice\drag_state_manager.dart"
    )
) else if "%TASK_NUMBER%"=="1.3" (
    echo 🎯 任务1.3: 性能监控系统
    set FILES=lib\presentation\pages\practices\widgets\m3_practice_edit_canvas.dart
    
    REM 创建新文件占位符
    if not exist "lib\presentation\widgets\practice" mkdir "lib\presentation\widgets\practice"
    if not exist "lib\presentation\widgets\practice\performance_monitor.dart" (
        echo // TODO: 实现PerformanceMonitor > "lib\presentation\widgets\practice\performance_monitor.dart"
    )
) else (
    echo ⚠️  未知任务编号: %TASK_NUMBER%
    set FILES=
)

for %%f in (%FILES%) do (
    if exist "%%f" (
        echo ✅ 找到文件: %%f
    ) else (
        echo ❌ 文件不存在: %%f
    )
)

REM 7. 开发环境准备
echo.
echo 🛠️  开发环境准备...

REM 检查设备（简化版，Windows下设备检查较复杂）
flutter devices > temp_devices.txt 2>&1
findstr /c:"No devices" temp_devices.txt > nul
if errorlevel 1 (
    echo ✅ 发现测试设备
) else (
    echo ⚠️  未发现可用测试设备
)
del temp_devices.txt 2>nul

REM 8. 性能工具准备
echo.
echo 📈 性能工具准备...

REM 创建性能测试目录
if not exist "test\performance" mkdir "test\performance"

REM 创建性能测试模板（如果不存在）
set TASK_FILE_NAME=%TASK_NUMBER:.=_%
set PERF_TEST_FILE=test\performance\task_%TASK_FILE_NAME%_test.dart

if not exist "%PERF_TEST_FILE%" (
(
echo import 'package:flutter_test/flutter_test.dart';
echo import 'package:flutter/material.dart';
echo.
echo /// 任务 %TASK_NUMBER% 性能测试
echo /// 
echo /// 测试目标:
echo /// - 验证性能优化效果
echo /// - 确保功能正确性
echo /// - 记录性能指标
echo void main^(^) {
echo   group^('任务 %TASK_NUMBER% 性能测试', ^(^) {
echo     testWidgets^('基础性能测试', ^(WidgetTester tester^) async {
echo       // TODO: 实现具体测试用例
echo       
echo       // 1. 构建测试环境
echo       
echo       // 2. 执行测试操作
echo       
echo       // 3. 验证性能指标
echo       
echo       // 4. 检查功能正确性
echo     }^);
echo     
echo     testWidgets^('压力测试', ^(WidgetTester tester^) async {
echo       // TODO: 实现压力测试用例
echo     }^);
echo     
echo     testWidgets^('内存泄漏测试', ^(WidgetTester tester^) async {
echo       // TODO: 实现内存测试用例
echo     }^);
echo   }^);
echo }
) > "%PERF_TEST_FILE%"
    echo ✅ 创建性能测试文件: %PERF_TEST_FILE%
)

REM 9. 创建工作日志
echo.
echo 📝 创建工作日志...

if not exist "docs\work_logs" mkdir "docs\work_logs"
set WORK_LOG_FILE=docs\work_logs\task_%TASK_FILE_NAME%_%YYYY%%MM%%DD%.md

(
echo # 任务 %TASK_NUMBER% 工作日志
echo.
echo **日期**: %YYYY%-%MM%-%DD%
echo **任务**: %TASK_NUMBER%
echo **开始时间**: %HH%:%Min%:%Sec%
echo.
echo ## 🎯 任务目标
echo [描述具体要实现的功能和性能目标]
echo.
echo ## 📋 工作计划
echo - [ ] [具体步骤1]
echo - [ ] [具体步骤2]
echo - [ ] [具体步骤3]
echo.
echo ## 💻 实际进展
echo.
echo ### %HH%:%Min% - 开始工作
echo - 环境检查完成
echo - 基线数据收集
echo - 准备工作完成
echo.
echo ### [时间] - [阶段描述]
echo - [具体工作内容]
echo - [遇到的问题]
echo - [解决方案]
echo.
echo ## 📊 性能数据记录
echo ### 优化前基线
echo - FPS: [数据]
echo - 内存: [数据]
echo - 响应时间: [数据]
echo.
echo ### 优化后结果
echo - FPS: [数据] ^(提升: [百分比]^)
echo - 内存: [数据] ^(优化: [百分比]^)
echo - 响应时间: [数据] ^(改善: [百分比]^)
echo.
echo ## 🚨 问题记录
echo 1. **[问题描述]**: [解决方案]
echo 2. **[问题描述]**: [解决方案]
echo.
echo ## ✅ 完成检查清单
echo - [ ] 功能实现完成
echo - [ ] 性能目标达成
echo - [ ] 测试用例通过
echo - [ ] 代码审查完成
echo - [ ] 文档更新完成
echo.
echo ## 📝 总结和下一步
echo [工作总结和后续计划]
echo.
echo ---
echo 结束时间: [填写]
echo 总耗时: [填写]
) > "%WORK_LOG_FILE%"

echo ✅ 创建工作日志: %WORK_LOG_FILE%

REM 10. 最终准备
echo.
echo 🎉 准备完成！
echo.
echo 📋 下一步操作:
echo 1. 打开IDE或编辑器
echo 2. 查看任务详情: docs\m3_canvas_task_tracker.md
echo 3. 参考日常检查: docs\m3_canvas_daily_checklist.md
echo 4. 开始编码实现
echo 5. 记录工作日志: %WORK_LOG_FILE%
echo.
echo 🔗 重要文件链接:
echo   - 任务跟踪: docs\m3_canvas_task_tracker.md
echo   - 工作日志: %WORK_LOG_FILE%
echo   - 基线数据: %BASELINE_FILE%
echo   - 性能测试: %PERF_TEST_FILE%
echo.
echo ⚡ 快速启动命令:
echo   flutter run --profile  # 性能模式运行
echo   flutter test %PERF_TEST_FILE%  # 运行性能测试
echo   flutter analyze  # 代码分析
echo.
echo 💡 记住: 每个小的改动都要及时测试和记录！
echo.
echo 🚀 开始工作吧！祝开发顺利！
echo.
pause
