@echo off
REM 文件清理脚本
REM 生成时间: C:\Users\wailik\Documents\Code\Flutter\demo\demo

echo 开始清理未使用的文件...

REM ===== 空文件删除 (安全) =====
del "lib/presentation/pages/library/components/category_dialog_new.dart"
del "lib/presentation/widgets/layouts/work_layout.dart"
del "lib/presentation/widgets/practice/property_panels/image/image_property_panel_export.dart"
del "lib/presentation/pages/practices/widgets/selection_box_painter.dart"
del "lib/presentation/widgets/layouts/sidebar_page.dart"
del "lib/presentation/pages/library/components/library_category_list_panel.dart"
echo 空文件删除完成

REM ===== 小文件删除 (需确认) =====
REM del "lib/presentation/widgets/section_header.dart"  REM 0.7KB
REM del "lib/presentation/widgets/practice/blend_mode_helper.dart"  REM 0.8KB
REM del "lib/widgets/character_edit/layers/events/layer_event.dart"  REM 0.9KB
REM del "lib/domain/models/character/character_usage.dart"  REM 0.6KB
REM del "lib/presentation/pages/works/components/filter/filter_chip_group.dart"  REM 1.0KB
REM del "lib/infrastructure/logging/log_category.dart"  REM 0.3KB
REM del "lib/presentation/widgets/indicators/button_progress_indicator.dart"  REM 0.6KB
REM del "lib/domain/enums/work_style.dart"  REM 1.0KB
REM del "lib/infrastructure/json/character_region_converter.dart"  REM 0.5KB
REM del "lib/presentation/widgets/loading_overlay.dart"  REM 0.3KB
REM del "lib/presentation/widgets/scroll/scrollable_container.dart"  REM 0.8KB
REM del "lib/presentation/widgets/displays/error_text.dart"  REM 0.7KB
REM del "lib/domain/enums/work_tool.dart"  REM 0.8KB
REM del "lib/presentation/widgets/common/base_card.dart"  REM 0.7KB
REM del "lib/presentation/widgets/practice/guideline_alignment/guideline_simple_painter.dart"  REM 0.9KB
REM del "lib/presentation/widgets/responsive_builder.dart"  REM 0.9KB
echo 小文件需要手动确认删除

echo 文件清理脚本生成完成
pause
