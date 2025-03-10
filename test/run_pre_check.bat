@echo off
setlocal EnableDelayedExpansion

echo [33m开始环境检查...[0m

REM 1. 验证环境
dart run test/utils/environment_validator.dart
if errorlevel 1 (
    echo [31m环境验证失败[0m
    echo [33m尝试自动修复...[0m
    
    dart run test/utils/environment_validator.dart --fix
    if errorlevel 1 (
        echo [31m自动修复失败，请手动检查环境配置[0m
        exit /b 1
    )
    
    echo [32m自动修复完成[0m
)

REM 2. 创建目录
mkdir test\logs\archive 2>nul
mkdir test\reports 2>nul
mkdir coverage\reports 2>nul
mkdir test\benchmark\results 2>nul

REM 3. 归档旧日志
set timestamp=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set timestamp=%timestamp: =0%
if exist test\logs\system_check.log (
    move test\logs\system_check.log "test\logs\archive\system_check_%timestamp%.log"
)

REM 4. 清理过期报告
forfiles /P test\reports /M *.* /D -7 /C "cmd /c del @path" 2>nul
forfiles /P coverage\reports /M *.* /D -7 /C "cmd /c del @path" 2>nul

REM 5. 检查磁盘空间
for /f "tokens=3" %%a in ('dir /-c 2^>nul ^| find "bytes free"') do set free_space=%%a
set /a free_space_mb=%free_space:~0,-3%/1024
if %free_space_mb% lss 1024 (
    echo [31m警告: 可用磁盘空间不足 (!free_space_mb!MB)[0m
    echo [33m建议至少保留 1GB 空间[0m
    choice /M "是否继续"
    if errorlevel 2 exit /b 1
)

REM 6. 备份关键文件
set backup_dir=test\backup\%date:~-4%%date:~3,2%%date:~0,2%
mkdir "%backup_dir%" 2>nul
for %%f in (pubspec.yaml test\README.md .github\workflows\test.yml) do (
    if exist "%%f" copy "%%f" "%backup_dir%\"
)

REM 7. 检查依赖项
echo [33m检查依赖项...[0m
set missing_deps=0

where dart >nul 2>nul
if errorlevel 1 (
    echo [31m未找到命令: dart[0m
    set /a missing_deps+=1
)

where git >nul 2>nul
if errorlevel 1 (
    echo [31m未找到命令: git[0m
    set /a missing_deps+=1
)

if !missing_deps! gtr 0 (
    echo [31m缺少必要的依赖项[0m
    exit /b 1
)

REM 8. 验证 Dart 包
echo [33m验证 Dart 包...[0m
dart pub get
if errorlevel 1 (
    echo [31m包依赖验证失败[0m
    exit /b 1
)

REM 9. 检查代码格式
echo [33m检查代码格式...[0m
dart format --output=none --set-exit-if-changed .
if errorlevel 1 (
    echo [31m代码格式检查失败[0m
    choice /M "是否自动格式化代码"
    if not errorlevel 2 (
        dart format .
    ) else (
        exit /b 1
    )
)

REM 10. 运行静态分析
echo [33m运行静态分析...[0m
dart analyze
if errorlevel 1 (
    echo [31m静态分析发现问题[0m
    exit /b 1
)

echo [32m预检查完成！[0m
echo - 环境验证: 通过
echo - 日志归档: 完成
echo - 空间检查: 通过
echo - 依赖检查: 通过
echo - 代码检查: 通过

exit /b 0