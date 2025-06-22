#!/usr/bin/env python3
"""
ARB YAML映射比较工具
此脚本比较两个YAML映射文件，显示它们之间的合并键差异。
"""

import os
import re
from collections import defaultdict

# 文件路径
REPORT_DIR = "arb_report"
AGGRESSIVE_YAML = os.path.join(REPORT_DIR, "key_mapping.yaml")
CONSERVATIVE_YAML = os.path.join(REPORT_DIR, "key_mapping_conservative.yaml")
COMPARISON_REPORT = os.path.join(REPORT_DIR, "mapping_comparison.txt")

def parse_yaml_mapping(file_path):
    """解析YAML映射文件，提取替换映射关系"""
    if not os.path.exists(file_path):
        print(f"错误: 找不到文件 {file_path}")
        return None
    
    replacements = {}
    current_primary = None
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            # 检查是否是主键行（不缩进）
            if not line.startswith(' '):
                if ': ' in line:
                    parts = line.split(': ', 1)
                    if len(parts) == 2:
                        key, rest = parts
                        key = key.strip()
                        
                        # 分离值和注释
                        if ' #' in rest:
                            comment_parts = rest.split(' #', 1)
                            if len(comment_parts) == 2:
                                value, comment = comment_parts
                                value = value.strip()
                                comment = comment.strip()
                                
                                # 如果是替换键
                                if "替代了其他key的" in comment:
                                    current_primary = key
                                else:
                                    current_primary = None
                        else:
                            current_primary = None
            
            # 检查是否是被替换的键（缩进）
            elif line.startswith(' ') and current_primary:
                if ': ' in line:
                    parts = line.split(': ', 1)
                    if len(parts) == 2:
                        key, value = parts
                        key = key.strip()
                        
                        # 跳过主键本身
                        if key != current_primary:
                            replacements[key] = current_primary
        
        return replacements
    except Exception as e:
        print(f"解析文件 {file_path} 时出错: {str(e)}")
        return {}

def compare_mappings():
    """比较两个YAML映射文件并生成报告"""
    # 解析两个YAML文件
    aggressive_mapping = parse_yaml_mapping(AGGRESSIVE_YAML)
    conservative_mapping = parse_yaml_mapping(CONSERVATIVE_YAML)
    
    if not aggressive_mapping or not conservative_mapping:
        return
    
    # 找出只在激进版本中存在的替换
    only_in_aggressive = {}
    for key, value in aggressive_mapping.items():
        if key not in conservative_mapping:
            only_in_aggressive[key] = value
    
    # 找出两个版本中替换目标不同的键
    different_replacements = {}
    for key, value in aggressive_mapping.items():
        if key in conservative_mapping and value != conservative_mapping[key]:
            different_replacements[key] = (value, conservative_mapping[key])
    
    # 按照主键分组差异
    aggressive_by_primary = defaultdict(list)
    for key, primary in only_in_aggressive.items():
        aggressive_by_primary[primary].append(key)
      # 生成报告
    with open(COMPARISON_REPORT, 'w', encoding='utf-8') as f:
        f.write("ARB映射比较报告\n")
        f.write("================\n\n")
        
        f.write(f"激进版映射替换总数: {len(aggressive_mapping) if aggressive_mapping else 0}\n")
        f.write(f"保守版映射替换总数: {len(conservative_mapping) if conservative_mapping else 0}\n")
        
        if aggressive_mapping and conservative_mapping:
            f.write(f"只在激进版中存在的替换: {len(only_in_aggressive)}\n")
            f.write(f"替换目标不同的键: {len(different_replacements)}\n\n")
            
            # 输出按主键分组的过度合并详情
            f.write("过度合并分析\n")
            f.write("------------\n\n")
            
            for primary, keys in sorted(aggressive_by_primary.items(), key=lambda x: len(x[1]), reverse=True):
                if len(keys) > 2:  # 只显示合并了多个键的情况
                    f.write(f"主键 '{primary}' 在激进版中额外合并了 {len(keys)} 个键:\n")
                    for key in sorted(keys):
                        f.write(f"  - {key}\n")
                    f.write("\n")
            
            # 输出替换目标不同的情况
            if different_replacements:
                f.write("\n替换目标不同的键\n")
                f.write("----------------\n\n")
                
                for key, (aggressive_target, conservative_target) in sorted(different_replacements.items()):
                    f.write(f"键 '{key}':\n")
                    f.write(f"  - 在激进版中替换为: '{aggressive_target}'\n")
                    f.write(f"  - 在保守版中替换为: '{conservative_target}'\n")
                    f.write("\n")
        else:
            f.write("\n无法完成比较，因为一个或两个映射文件无法正确解析。\n")
    
    print(f"比较报告已生成: {COMPARISON_REPORT}")
    if aggressive_mapping and conservative_mapping:
        print(f"激进版替换: {len(aggressive_mapping)}, 保守版替换: {len(conservative_mapping)}")
        print(f"差异数量: {len(only_in_aggressive) + len(different_replacements)}")
    else:
        print("无法完成比较，因为一个或两个映射文件无法正确解析。")

if __name__ == "__main__":
    print("正在比较ARB映射文件...")
    compare_mappings()
    print("完成!")
