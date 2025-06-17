#!/usr/bin/env python3
"""
简单的本地化修复演示 - 处理具体文件的导入和硬编码文本替换
"""

import os
import re

def analyze_dart_file(file_path):
    """分析Dart文件，检查本地化状态"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    analysis = {
        'has_material_import': 'package:flutter/material.dart' in content,
        'has_l10n_import': any([
            'package:flutter_gen/gen_l10n/app_localizations.dart' in content,
            'generated/l10n/l10n.dart' in content,
            'from \'../../../generated/l10n.dart\'' in content
        ]),
        'uses_s_of_context': 'S.of(context)' in content,
        'hardcoded_chinese': [],
        'existing_imports': []
    }
    
    # 查找硬编码中文文本
    chinese_pattern = r'[\'"][^\'\"]*[\u4e00-\u9fff][^\'\"]*[\'"]'
    matches = re.finditer(chinese_pattern, content)
    for match in matches:
        text = match.group()
        line_num = content[:match.start()].count('\n') + 1
        analysis['hardcoded_chinese'].append({
            'text': text,
            'line': line_num,
            'start': match.start(),
            'end': match.end()
        })
    
    # 提取导入语句
    import_lines = []
    for i, line in enumerate(content.split('\n'), 1):
        if line.strip().startswith('import '):
            import_lines.append((i, line.strip()))
    analysis['existing_imports'] = import_lines
    
    return analysis

def add_l10n_import(content):
    """添加本地化导入"""
    lines = content.split('\n')
    
    # 查找合适的插入位置
    last_import_index = -1
    for i, line in enumerate(lines):
        if line.strip().startswith('import '):
            last_import_index = i
    
    # 检查是否已有l10n导入
    l10n_imports = [
        "import '../../../generated/l10n.dart';",
        "import 'package:flutter_gen/gen_l10n/app_localizations.dart';"
    ]
    
    has_l10n = any(any(imp in line for imp in l10n_imports) for line in lines)
    
    if not has_l10n:
        # 添加本地化导入
        insert_pos = last_import_index + 1 if last_import_index >= 0 else 0
        lines.insert(insert_pos, "import '../../../generated/l10n.dart';")
        print(f"  📦 添加本地化导入到第 {insert_pos + 1} 行")
    else:
        print("  📦 本地化导入已存在")
    
    return '\n'.join(lines)

def fix_hardcoded_text(content, hardcoded_items, arb_mappings):
    """替换硬编码文本"""
    # 按位置倒序排列，避免替换后位置偏移
    sorted_items = sorted(hardcoded_items, key=lambda x: x['start'], reverse=True)
    
    for item in sorted_items:
        text = item['text']
        clean_text = text[1:-1]  # 移除引号
        
        # 查找对应的ARB键
        arb_key = arb_mappings.get(clean_text)
        if arb_key:
            replacement = f"S.of(context).{arb_key}"
            content = content[:item['start']] + replacement + content[item['end']:]
            print(f"  ✅ 第 {item['line']} 行: {text} -> {replacement}")
        else:
            print(f"  ⚠️  第 {item['line']} 行: {text} - 未找到ARB映射")
    
    return content

def demonstrate_l10n_fix():
    """演示本地化修复过程"""
    file_path = "lib/presentation/widgets/works/preview_mode_config.dart"
    
    if not os.path.exists(file_path):
        print(f"❌ 文件不存在: {file_path}")
        return
    
    print(f"\n🔍 分析文件: {file_path}")
    
    # 分析文件
    analysis = analyze_dart_file(file_path)
    
    print(f"\n📊 分析结果:")
    print(f"  Material导入: {'✅' if analysis['has_material_import'] else '❌'}")
    print(f"  本地化导入: {'✅' if analysis['has_l10n_import'] else '❌'}")
    print(f"  使用S.of(context): {'✅' if analysis['uses_s_of_context'] else '❌'}")
    print(f"  硬编码中文: {len(analysis['hardcoded_chinese'])} 个")
    
    if analysis['hardcoded_chinese']:
        print(f"\n📝 发现的硬编码中文:")
        for item in analysis['hardcoded_chinese']:
            print(f"  第 {item['line']} 行: {item['text']}")
    
    # 示例ARB映射
    arb_mappings = {
        "保存更改": "saveChanges",
        "添加图片": "addImage", 
        "删除图片": "deleteImage"
    }
    
    # 读取原始内容
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print(f"\n🔧 开始修复:")
    
    # 添加导入
    if not analysis['has_l10n_import']:
        content = add_l10n_import(content)
    
    # 替换硬编码文本
    if analysis['hardcoded_chinese']:
        content = fix_hardcoded_text(content, analysis['hardcoded_chinese'], arb_mappings)
    
    # 保存修复后的内容（演示用）
    output_path = f"{file_path}.fixed_demo"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"\n✅ 修复完成！演示结果保存到: {output_path}")
    print(f"\n📋 修复总结:")
    print(f"  - 已确保本地化导入存在")
    print(f"  - 已替换 {len([item for item in analysis['hardcoded_chinese'] if item['text'][1:-1] in arb_mappings])} 个硬编码文本")
    
    # 显示修复后的关键部分
    print(f"\n📄 修复后的关键部分:")
    lines = content.split('\n')
    for i, line in enumerate(lines[:10], 1):
        if 'import' in line or 'S.of(context)' in line:
            print(f"  {i:2d}: {line}")

if __name__ == "__main__":
    demonstrate_l10n_fix()
