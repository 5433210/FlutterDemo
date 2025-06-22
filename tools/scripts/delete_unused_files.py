#!/usr/bin/env python3
"""
删除第一类（空文件）和第二类（小文件）未使用文件
总共22个文件
"""

import os
from pathlib import Path

def delete_unused_files():
    """删除未使用的文件"""
    project_root = Path.cwd()
    
    # 第一类：空文件 (6个) - 立即删除
    empty_files = [
        'lib/presentation/pages/library/components/category_dialog_new.dart',
        'lib/presentation/widgets/layouts/work_layout.dart',
        'lib/presentation/widgets/practice/property_panels/image/image_property_panel_export.dart',
        'lib/presentation/pages/practices/widgets/selection_box_painter.dart',
        'lib/presentation/widgets/layouts/sidebar_page.dart',
        'lib/presentation/pages/library/components/library_category_list_panel.dart',
    ]
    
    # 第二类：小文件 (16个) - 谨慎删除
    small_files = [
        'lib/presentation/widgets/section_header.dart',
        'lib/presentation/widgets/practice/blend_mode_helper.dart',
        'lib/widgets/character_edit/layers/events/layer_event.dart',
        'lib/domain/models/character/character_usage.dart',
        'lib/presentation/pages/works/components/filter/filter_chip_group.dart',
        'lib/infrastructure/logging/log_category.dart',
        'lib/presentation/widgets/indicators/button_progress_indicator.dart',
        'lib/domain/enums/work_style.dart',
        'lib/infrastructure/json/character_region_converter.dart',
        'lib/presentation/widgets/loading_overlay.dart',
        'lib/presentation/widgets/scroll/scrollable_container.dart',
        'lib/presentation/widgets/displays/error_text.dart',
        'lib/domain/enums/work_tool.dart',
        'lib/presentation/widgets/common/base_card.dart',
        'lib/presentation/widgets/practice/guideline_alignment/guideline_simple_painter.dart',
        'lib/presentation/widgets/responsive_builder.dart',
    ]
    
    all_files = empty_files + small_files
    deleted_count = 0
    not_found_count = 0
    error_count = 0
    
    print("=" * 80)
    print("🗑️  开始删除未使用文件")
    print("=" * 80)
    print(f"📊 计划删除: {len(all_files)} 个文件")
    print()
    
    # 删除空文件
    print("✅ 删除第一类：空文件")
    for i, file_path in enumerate(empty_files, 1):
        full_path = project_root / file_path
        print(f"   {i:2d}. {file_path}")
        
        if full_path.exists():
            try:
                full_path.unlink()
                print(f"       ✓ 已删除")
                deleted_count += 1
            except Exception as e:
                print(f"       ✗ 删除失败: {e}")
                error_count += 1
        else:
            print(f"       - 文件不存在")
            not_found_count += 1
    
    print()
    
    # 删除小文件
    print("⚠️  删除第二类：小文件")
    for i, file_path in enumerate(small_files, 1):
        full_path = project_root / file_path
        print(f"   {i:2d}. {file_path}")
        
        if full_path.exists():
            try:
                # 检查文件大小
                size = full_path.stat().st_size
                print(f"       📏 文件大小: {size/1024:.1f}KB")
                
                full_path.unlink()
                print(f"       ✓ 已删除")
                deleted_count += 1
            except Exception as e:
                print(f"       ✗ 删除失败: {e}")
                error_count += 1
        else:
            print(f"       - 文件不存在")
            not_found_count += 1
    
    print()
    print("=" * 80)
    print("📊 删除统计")
    print("=" * 80)
    print(f"✅ 成功删除: {deleted_count} 个文件")
    print(f"❌ 删除失败: {error_count} 个文件")
    print(f"🔍 文件不存在: {not_found_count} 个文件")
    print(f"📋 总计处理: {deleted_count + error_count + not_found_count} 个文件")
    
    if deleted_count > 0:
        print()
        print("💡 建议下一步操作:")
        print("   1. 运行 flutter clean")
        print("   2. 运行 flutter pub get")
        print("   3. 运行 flutter analyze 检查是否有问题")
        print("   4. 运行测试确保应用正常工作")
    
    # 清理空目录
    print()
    print("🧹 清理空目录...")
    _clean_empty_directories(project_root / 'lib')

def _clean_empty_directories(root_dir):
    """清理空目录"""
    cleaned = 0
    
    # 递归查找空目录（从最深层开始）
    for dirpath, dirnames, filenames in os.walk(root_dir, topdown=False):
        if not dirnames and not filenames:  # 空目录
            try:
                os.rmdir(dirpath)
                rel_path = Path(dirpath).relative_to(Path.cwd())
                print(f"   🗂️  清理空目录: {rel_path}")
                cleaned += 1
            except:
                pass
    
    if cleaned > 0:
        print(f"   ✅ 清理了 {cleaned} 个空目录")
    else:
        print("   📁 没有发现空目录")

if __name__ == "__main__":
    delete_unused_files() 