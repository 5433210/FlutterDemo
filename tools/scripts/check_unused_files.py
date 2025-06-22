#!/usr/bin/env python3
import os
import re
import subprocess

def find_imports_and_usage(file_name_without_extension):
    """查找文件的导入和使用情况"""
    # 搜索文件名的导入
    import_result = subprocess.run([
        'grep', '-r', '--include=*.dart', '-l', f'import.*{file_name_without_extension}', 'lib/'
    ], capture_output=True, text=True, cwd='.')
    
    # 搜索类名的使用
    class_name = ''.join(word.capitalize() for word in file_name_without_extension.split('_'))
    usage_result = subprocess.run([
        'grep', '-r', '--include=*.dart', '-l', class_name, 'lib/'
    ], capture_output=True, text=True, cwd='.')
    
    imports = import_result.stdout.strip().split('\n') if import_result.stdout.strip() else []
    usages = usage_result.stdout.strip().split('\n') if usage_result.stdout.strip() else []
    
    # 过滤掉文件自身
    target_file = f'lib/presentation/widgets/{file_name_without_extension}.dart'
    target_file2 = f'lib/presentation/pages/{file_name_without_extension}.dart'
    target_file3 = f'lib/presentation/widgets/demo/{file_name_without_extension}.dart'
    target_file4 = f'lib/presentation/pages/practices/widgets/{file_name_without_extension}.dart'
    
    imports = [f for f in imports if f and f not in [target_file, target_file2, target_file3, target_file4]]
    usages = [f for f in usages if f and f not in [target_file, target_file2, target_file3, target_file4]]
    
    return imports, usages

# 可疑的未使用文件列表
suspicious_files = [
    'element_snapshot_example',
    'expansion_tile_memory_demo', 
    'error_boundary',
    'confirmation_dialog',
    'font_tester',
    'font_weight_tester'
]

print("🔍 检查可疑未使用文件:")
print()

for file_name in suspicious_files:
    imports, usages = find_imports_and_usage(file_name)
    
    print(f"📄 {file_name}.dart:")
    
    if not imports and not usages:
        print("   ❌ 未发现任何导入或使用")
    else:
        if imports:
            print(f"   📥 导入: {len(imports)} 处")
            for imp in imports[:3]:  # 只显示前3个
                print(f"      - {imp}")
            if len(imports) > 3:
                print(f"      ... 还有 {len(imports) - 3} 处")
        
        if usages:
            print(f"   🔗 使用: {len(usages)} 处")
            for usage in usages[:3]:  # 只显示前3个
                print(f"      - {usage}")
            if len(usages) > 3:
                print(f"      ... 还有 {len(usages) - 3} 处")
    
    print()
