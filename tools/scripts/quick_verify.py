#!/usr/bin/env python3
import os
import re
from pathlib import Path

def main():
    project_root = Path('.')
    lib_dir = project_root / 'lib'
    
    # 扫描所有文件
    all_dart = list(lib_dir.rglob('*.dart'))
    excluded = [f for f in all_dart if f.name.endswith('.g.dart') or f.name.endswith('.freezed.dart')]
    valid_files = [f for f in all_dart if not f.name.endswith('.g.dart') and not f.name.endswith('.freezed.dart')]
    
    print(f'📊 文件统计:')
    print(f'   lib目录总Dart文件: {len(all_dart)}')
    print(f'   代码生成文件: {len(excluded)}')
    print(f'   有效文件: {len(valid_files)}')
    
    # 检查关键文件
    key_files = ['lib/main.dart', 'lib/presentation/app.dart']
    print(f'\n🔍 关键文件检查:')
    for file_path in key_files:
        exists = (project_root / file_path).exists()
        print(f'   {file_path}: {"存在" if exists else "不存在"}')
    
    # 分析一个简单的导入关系
    main_file = project_root / 'lib/main.dart'
    if main_file.exists():
        with open(main_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 查找导入
        imports = re.findall(r"import\s+['\"]([^'\"]+)['\"]", content)
        package_imports = [imp for imp in imports if imp.startswith('package:demo/')]
        relative_imports = [imp for imp in imports if imp.startswith('.')]
        
        print(f'\n📚 main.dart 导入分析:')
        print(f'   总导入数: {len(imports)}')
        print(f'   包导入: {len(package_imports)}')
        print(f'   相对导入: {len(relative_imports)}')
        
        if package_imports:
            print(f'   示例包导入:')
            for imp in package_imports[:3]:
                lib_path = imp.replace('package:demo/', 'lib/')
                print(f'     {imp} -> {lib_path}')
    
    # 检查一些可能未使用的文件
    print(f'\n🧐 随机检查10个文件的大小:')
    import random
    sample_files = random.sample(valid_files, min(10, len(valid_files)))
    for f in sample_files:
        size = f.stat().st_size
        rel_path = f.relative_to(project_root)
        print(f'   {rel_path} ({size}字节)')

if __name__ == "__main__":
    main() 