@echo off
echo 开始删除未使用的文件...

REM 删除 application 目录下的文件
del /Q "lib\application\config\app_config.dart"
del /Q "lib\application\providers\image_providers.dart"
del /Q "lib\application\providers\settings_providers.dart"
del /Q "lib\application\repositories\repositories.dart"
del /Q "lib\application\services\image\erase_manager.dart"
del /Q "lib\application\services\image\erase_processor.dart"
del /Q "lib\application\services\work\work_service_error_handler.dart"

REM 删除 domain 目录下的文件
del /Q "lib\domain\models\character\path_render_data.dart"
del /Q "lib\domain\models\work\work_metadata.dart"
del /Q "lib\domain\repositories\repositories.dart"

REM 删除 infrastructure 目录下的文件
del /Q "lib\infrastructure\events\event_bus.dart"
del /Q "lib\infrastructure\logging\app_error_handler.dart"
del /Q "lib\infrastructure\logging\error_handler.dart"
del /Q "lib\infrastructure\persistence\app_database.dart"
del /Q "lib\infrastructure\persistence\database_factory.dart"
del /Q "lib\infrastructure\persistence\database_state.dart"
del /Q "lib\infrastructure\persistence\file\file_storage.dart"
del /Q "lib\infrastructure\persistence\mock_database.dart"
del /Q "lib\infrastructure\persistence\sqlite\database_error_handler.dart"
del /Q "lib\infrastructure\providers\persistence_provider.dart"

REM 删除 presentation 目录下的文件
del /Q "lib\presentation\constants\work_card_styles.dart"
del /Q "lib\presentation\dialogs\work_import\components\preview\drop_target.dart"
del /Q "lib\presentation\dialogs\work_import\components\preview\image_drop_target.dart"
del /Q "lib\presentation\dialogs\work_import\components\preview\image_viewer.dart"
del /Q "lib\presentation\pages\characters\character_detail_page.dart"
del /Q "lib\presentation\pages\communication_example.dart"
del /Q "lib\presentation\pages\settings\panels\general_settings_panel.dart"
del /Q "lib\presentation\pages\settings\panels\storage_settings_panel.dart"
rd /S /Q "lib\presentation\pages\works\components\filter"
rd /S /Q "lib\presentation\pages\works\components\toolbar"
del /Q "lib\presentation\pages\works\components\image_error_view.dart"
del /Q "lib\presentation\pages\works\components\image_operations_toolbar.dart"
del /Q "lib\presentation\pages\works\components\image_viewer.dart"
del /Q "lib\presentation\pages\works\components\info_card.dart"
del /Q "lib\presentation\pages\works\components\layout\work_layout.dart"
del /Q "lib\presentation\pages\works\components\loading_state.dart"
del /Q "lib\presentation\pages\works\components\work_grid.dart"
del /Q "lib\presentation\pages\works\components\work_tabs.dart"
del /Q "lib\presentation\pages\works\components\work_toolbar.dart"

REM 删除 providers 目录下的文件
del /Q "lib\presentation\providers\character\auto_save_provider.dart"
del /Q "lib\presentation\providers\character\character_region_sync_fix.dart"
del /Q "lib\presentation\providers\character\edit_panel_provider.dart"
del /Q "lib\presentation\providers\error_boundary_provider.dart"
del /Q "lib\presentation\providers\error_handler_provider.dart"
del /Q "lib\presentation\providers\error_provider.dart"
del /Q "lib\presentation\providers\loading_provider.dart"
del /Q "lib\presentation\providers\works_state_providers.dart"
del /Q "lib\presentation\providers\work_filter_provider.dart"

REM 删除 widgets 目录下的文件
rd /S /Q "lib\presentation\widgets\character_collection\erase_tool"
del /Q "lib\presentation\widgets\base_page.dart"
del /Q "lib\presentation\widgets\character\character_extraction_panel.dart"
del /Q "lib\presentation\widgets\character_collection\action_buttons.dart"
del /Q "lib\presentation\widgets\character_collection\character_input.dart"
del /Q "lib\presentation\widgets\character_collection\debug_toolbar.dart"
del /Q "lib\presentation\widgets\character_collection\edit_toolbar.dart"
del /Q "lib\presentation\widgets\character_collection\region_info_bar.dart"
del /Q "lib\presentation\widgets\character_collection\zoom_control_bar.dart"

REM 删除其他工具类文件
rd /S /Q "lib\tools\debug"
del /Q "lib\tools\erase\erase_controller.dart"
del /Q "lib\tools\generate_code.dart"
del /Q "lib\utils\chinese_helper.dart"
rd /S /Q "lib\utils\color"
rd /S /Q "lib\utils\debug"
rd /S /Q "lib\utils\performance"
del /Q "lib\utils\diagnostic_helper.dart"
del /Q "lib\utils\path\path_smoothing.dart"
del /Q "lib\utils\route_observer_helper.dart"
del /Q "lib\utils\safe_metadata_helper.dart"
del /Q "lib\widgets\character_edit\dialogs\shortcuts_help_dialog.dart"
del /Q "lib\widgets\character_edit\layers\events\event_dispatcher.dart"

echo 删除完成！
pause