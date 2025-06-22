#!/usr/bin/env python3
import json
import re
from pathlib import Path

def check_file_usage(file_path, project_root):
    """检查文件是否被其他文件使用"""
    target_file = project_root / file_path
    if not target_file.exists():
        return {'exists': False, 'references': []}
    
    references = []
    file_name = target_file.stem  # 不带扩展名的文件名
    
    # 在所有dart文件中搜索引用
    for dart_file in project_root.rglob('*.dart'):
        if dart_file == target_file:
            continue
        
        try:
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # 检查各种可能的引用方式
            patterns = [
                f"'{file_path}'",  # 直接路径引用
                f'"{file_path}"',  # 直接路径引用
                f"'{file_name}'",  # 文件名引用
                f'"{file_name}"',  # 文件名引用
                f'{file_name}',    # 类名或函数名引用
            ]
            
            for pattern in patterns:
                if pattern in content:
                    rel_path = str(dart_file.relative_to(project_root))
                    if rel_path not in references:
                        references.append(rel_path)
                    break
                    
        except Exception:
            continue
    
    return {
        'exists': True,
        'size': target_file.stat().st_size,
        'references': references
    }

def main():
    project_root = Path('.')
    
    # 读取分析结果
    with open('tools/reports/complete_file_analysis.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    unused_files = data.get('unused_lib_files', [])
    
    print(f"📊 验证未使用文件统计")
    print(f"   报告显示未使用文件: {len(unused_files)}个")
    
    # 检查前20个文件
    print(f"\n🔍 手动检查前20个未使用文件:")
    
    false_positives = []
    truly_unused = []
    
    for i, file_info in enumerate(unused_files[:20]):
        if isinstance(file_info, dict):
            file_path = file_info.get('path', '')
        else:
            file_path = str(file_info)
        
        if not file_path:
            continue
            
        result = check_file_usage(file_path, project_root)
        
        print(f"   {i+1:2d}. {file_path}")
        
        if not result['exists']:
            print(f"       ❌ 文件不存在")
            continue
            
        size_kb = result['size'] / 1024
        print(f"       📏 大小: {size_kb:.1f}KB")
        print(f"       🔗 被引用: {len(result['references'])}次")
        
        if result['references']:
            print(f"       📂 引用者: {result['references'][:3]}...")
            false_positives.append(file_path)
        else:
            truly_unused.append(file_path)
        
        print()
    
    # 总结
    print(f"📈 验证结果总结:")
    print(f"   检查文件数: 20")
    print(f"   可能误报: {len(false_positives)}个")
    print(f"   确实未使用: {len(truly_unused)}个")
    
    if false_positives:
        print(f"   误报率: {len(false_positives)/20*100:.1f}%")
        print(f"\n⚠️  可能误报的文件:")
        for fp in false_positives:
            print(f"      - {fp}")
    
    if truly_unused:
        print(f"\n✅ 确实未使用的文件:")
        for tu in truly_unused[:5]:
            print(f"      - {tu}")
        if len(truly_unused) > 5:
            print(f"      ... 还有{len(truly_unused)-5}个")

if __name__ == "__main__":
    main() 