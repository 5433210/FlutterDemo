#!/usr/bin/env python3
import os
import re
import subprocess

def find_file_usage(file_path):
    """查找指定文件的使用情况"""
    file_name = os.path.basename(file_path).replace('.dart', '')
    
    try:
        # 搜索文件名的导入（精确匹配）
        import_result = subprocess.run([
            'grep', '-r', '--include=*.dart', '-n', f'import.*{file_name}', 'lib/'
        ], capture_output=True, text=True, cwd='.', encoding='utf-8', errors='ignore')
        
        # 搜索可能的类名使用（转换为驼峰命名）
        class_name = ''.join(word.capitalize() for word in file_name.split('_'))
        if class_name != file_name:
            usage_result = subprocess.run([
                'grep', '-r', '--include=*.dart', '-n', class_name, 'lib/'
            ], capture_output=True, text=True, cwd='.', encoding='utf-8', errors='ignore')
        else:
            usage_result = None
    except Exception as e:
        print(f"搜索错误: {file_path} - {e}")
        return False, [], []
    
    imports = import_result.stdout.strip().split('\n') if import_result.stdout.strip() else []
    usages = []
    if usage_result and hasattr(usage_result, 'stdout') and usage_result.stdout:
        usages = usage_result.stdout.strip().split('\n') if usage_result.stdout.strip() else []
    
    # 过滤掉文件自身的引用
    target_file = file_path
    imports = [line for line in imports if line and target_file not in line]
    usages = [line for line in usages if line and target_file not in line]
    
    return len(imports) > 0 or len(usages) > 0, imports, usages

# 包含硬编码中文文本的文件列表（从用户提供的列表中提取）
hardcoded_files = [
    'lib/utils/app_restart_service.dart',
    'lib/infrastructure/utils/app_restart.dart', 
    'lib/presentation/dialogs/common/dialogs.dart',
    'lib/presentation/dialogs/common/dialog_button_group.dart',
    'lib/presentation/dialogs/practice/practice_title_edit_dialog.dart',
    'lib/presentation/dialogs/work_import/components/form/work_import_form.dart',
    'lib/presentation/dialogs/work_import/components/preview/work_import_preview.dart',
    'lib/presentation/pages/home_page.dart',
    'lib/presentation/pages/library/components/category_batch_assign_dialog.dart',
    'lib/presentation/pages/library/components/category_dialog.dart',
    'lib/presentation/pages/library/components/m3_library_detail_panel.dart',
    'lib/presentation/pages/library/components/m3_library_management_page.dart',
    'lib/presentation/pages/practices/utils/clipboard_enhancements.dart',
    'lib/presentation/pages/practices/widgets/m3_practice_edit_page.dart',
    'lib/presentation/pages/practices/widgets/element_snapshot_example.dart',
    'lib/presentation/pages/works/components/work_images_management_view.dart',
    'lib/presentation/pages/works/utils/cross_navigation_helper.dart',
    'lib/presentation/widgets/character_management/character_detail_view.dart',
    'lib/presentation/widgets/character_management/batch_action_bar.dart',
    'lib/presentation/widgets/common/advanced_image_preview.dart',
    'lib/presentation/widgets/common/base_image_preview.dart',
    'lib/presentation/widgets/common/color_palette_widget.dart',
    'lib/presentation/widgets/common/color_picker_dialog.dart',
    'lib/presentation/widgets/common/confirm_dialog.dart',
    'lib/presentation/widgets/common/editable_number_field.dart',
    'lib/presentation/widgets/common/error_display.dart',
    'lib/presentation/widgets/common/error_view.dart',
    'lib/presentation/widgets/common/m3_color_picker.dart',
    'lib/presentation/widgets/common/date_range_picker.dart',
    'lib/presentation/widgets/demo/expansion_tile_memory_demo.dart',
    'lib/presentation/widgets/dialogs/confirmation_dialog.dart',
    'lib/presentation/widgets/error_boundary.dart',
    'lib/presentation/widgets/font_tester.dart',
    'lib/presentation/widgets/font_weight_tester.dart',
    'lib/presentation/widgets/works/tag_editor.dart',
    'lib/presentation/widgets/works/work_form.dart',
    'lib/presentation/widgets/works/date_input_field.dart',
    'lib/presentation/pages/library/components/m3_library_browsing_panel.dart',
    'lib/presentation/widgets/practice/collection_element_renderer.dart',
    'lib/presentation/widgets/practice/element_renderers.dart',
    'lib/presentation/dialogs/practice/export_dialog.dart',
    'lib/presentation/pages/practices/utils/file_operations.dart',
    'lib/presentation/widgets/practice/background/m3_background_texture_panel.dart',
    'lib/presentation/widgets/practice/image_selection_handler.dart',
    'lib/presentation/widgets/practice/property_panels/m3_practice_property_panel_text.dart',
    'lib/presentation/widgets/practice/property_panels/property_panel_base.dart',
    'lib/presentation/widgets/practice/text_renderer.dart',
    'lib/presentation/widgets/works/enhanced_work_preview.dart',
    'lib/application/services/app_restart_service.dart'
]

print("📊 硬编码中文文本文件使用情况分析")
print("=" * 50)
print()

unused_files = []
used_files = []

for file_path in hardcoded_files:
    if not os.path.exists(file_path):
        print(f"⚠️  文件不存在: {file_path}")
        continue
        
    is_used, imports, usages = find_file_usage(file_path)
    
    file_name = os.path.basename(file_path)
    
    if not is_used:
        unused_files.append(file_path)
        print(f"❌ {file_name} - 未使用")
    else:
        used_files.append(file_path)
        print(f"✅ {file_name} - 已使用 (导入:{len(imports)}, 使用:{len(usages)})")

print()
print("📋 总结:")
print(f"✅ 已使用文件: {len(used_files)} 个")
print(f"❌ 未使用文件: {len(unused_files)} 个")
print()

if unused_files:
    print("🔥 建议优先处理的未使用文件 (可考虑删除或暂缓本地化):")
    for file_path in unused_files:
        print(f"   - {file_path}")
    print()

print("💡 建议:")
print("1. 未使用的文件可以考虑删除或暂缓本地化工作")
print("2. 已使用的文件应该按优先级进行本地化")
print("3. 核心功能文件应该优先本地化")
