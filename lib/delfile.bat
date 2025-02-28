@echo off
echo 开始清理冗余文件...
echo.

set PROJECT_PATH=C:\Users\wailik\Documents\Code\Flutter\demo\demo\lib

:: 1. 删除边栏切换组件重复文件
echo 删除重复的边栏切换组件...
if exist "%PROJECT_PATH%\presentation\pages\works\components\filter\sidebar_toggle.dart" (
    del /q "%PROJECT_PATH%\presentation\pages\works\components\filter\sidebar_toggle.dart"
    echo - 已删除 sidebar_toggle.dart [浏览页版本]
) else (
    echo - 文件不存在: sidebar_toggle.dart [浏览页版本]
)

if exist "%PROJECT_PATH%\presentation\pages\works\components\work_detail_sidebar_toggle.dart" (
    del /q "%PROJECT_PATH%\presentation\pages\works\components\work_detail_sidebar_toggle.dart"
    echo - 已删除 work_detail_sidebar_toggle.dart
) else (
    echo - 文件不存在: work_detail_sidebar_toggle.dart
)

if exist "%PROJECT_PATH%\presentation\pages\work_browser\components\sidebar_toggle.dart" (
    del /q "%PROJECT_PATH%\presentation\pages\work_browser\components\sidebar_toggle.dart"
    echo - 已删除 sidebar_toggle.dart [work_browser版本]
) else (
    echo - 文件不存在: sidebar_toggle.dart [work_browser版本]
)

:: 2. 删除空状态组件重复文件
echo.
echo 删除重复的空状态组件...
if exist "%PROJECT_PATH%\presentation\pages\characters\components\empty_state.dart" (
    del /q "%PROJECT_PATH%\presentation\pages\characters\components\empty_state.dart"
    echo - 已删除 empty_state.dart [字符页版本]
) else (
    echo - 文件不存在: empty_state.dart [字符页版本]
)

if exist "%PROJECT_PATH%\presentation\pages\works\components\content\empty_state.dart" (
    del /q "%PROJECT_PATH%\presentation\pages\works\components\content\empty_state.dart"
    echo - 已删除 empty_state.dart [作品页版本]
) else (
    echo - 文件不存在: empty_state.dart [作品页版本]
)

if exist "%PROJECT_PATH%\presentation\pages\practices\components\empty_state.dart" (
    del /q "%PROJECT_PATH%\presentation\pages\practices\components\empty_state.dart"
    echo - 已删除 empty_state.dart [练习页版本]
) else (
    echo - 文件不存在: empty_state.dart [练习页版本]
)

if exist "%PROJECT_PATH%\presentation\widgets\empty\empty_placeholder.dart" (
    del /q "%PROJECT_PATH%\presentation\widgets\empty\empty_placeholder.dart"
    echo - 已删除 empty_placeholder.dart
) else (
    echo - 文件不存在: empty_placeholder.dart
)

:: 3. 删除重复的服务类文件
echo.
echo 删除重复的服务类文件...
if exist "%PROJECT_PATH%\application\services\character_service.dart" (
    del /q "%PROJECT_PATH%\application\services\character_service.dart"
    echo - 已删除 character_service.dart [顶层版本]
) else (
    echo - 文件不存在: character_service.dart [顶层版本]
)

if exist "%PROJECT_PATH%\application\services\practice_service.dart" (
    del /q "%PROJECT_PATH%\application\services\practice_service.dart"
    echo - 已删除 practice_service.dart [顶层版本]
) else (
    echo - 文件不存在: practice_service.dart [顶层版本]
)

if exist "%PROJECT_PATH%\application\services\settings_service.dart" (
    del /q "%PROJECT_PATH%\application\services\settings_service.dart"
    echo - 已删除 settings_service.dart [顶层版本]
) else (
    echo - 文件不存在: settings_service.dart [顶层版本]
)

:: 4. 删除重复的错误处理组件
echo.
echo 删除重复的错误处理组件...
if exist "%PROJECT_PATH%\presentation\pages\works\components\error_state.dart" (
    del /q "%PROJECT_PATH%\presentation\pages\works\components\error_state.dart"
    echo - 已删除 error_state.dart
) else (
    echo - 文件不存在: error_state.dart
)

if exist "%PROJECT_PATH%\presentation\pages\works\components\error_view.dart" (
    del /q "%PROJECT_PATH%\presentation\pages\works\components\error_view.dart"
    echo - 已删除 error_view.dart
) else (
    echo - 文件不存在: error_view.dart
)

:: 5. 删除应合并的路径帮助工具
echo.
echo 确认是否已合并路径帮助工具文件...
if exist "%PROJECT_PATH%\utils\work_path_helper.dart" (
    echo - 提醒: work_path_helper.dart 仍然存在，请确认功能已合并到 path_helper.dart 后手动删除
) else (
    echo - work_path_helper.dart 已不存在，无需操作
)

echo.
echo 清理完成！请检查以上日志确认删除结果。
echo 注意：删除文件前请确保已更新所有相关引用，并已在版本控制系统中提交更改。
pause