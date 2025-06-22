#!/usr/bin/env python3
"""
检查ARB文件中存在但在映射文件中未定义的键
"""

import json
import os

# 文件路径
ARB_PATH = "lib/l10n/app_zh.arb"
YAML_MAPPING_PATH = "arb_report/custom_key_mapping.yaml"

def load_arb_keys():
    """加载ARB文件中的所有键"""
    if not os.path.exists(ARB_PATH):
        print(f"错误: ARB文件 {ARB_PATH} 不存在!")
        return set()
    
    with open(ARB_PATH, 'r', encoding='utf-8') as f:
        arb_data = json.load(f)
    
    # 只获取非元数据键
    arb_keys = set(key for key in arb_data.keys() if not key.startswith('@'))
    return arb_keys

def load_yaml_mapping_keys():
    """加载YAML映射文件中定义的所有键"""
    if not os.path.exists(YAML_MAPPING_PATH):
        print(f"错误: YAML映射文件 {YAML_MAPPING_PATH} 不存在!")
        return set()
    
    yaml_keys = set()
    
    with open(YAML_MAPPING_PATH, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    for line in lines:
        original_line = line
        line = line.strip()
        
        # 跳过空行和注释行
        if not line or line.startswith('#'):
            continue
        
        # 解析键值对
        if ': ' in line:
            key, value = line.split(': ', 1)
            key = key.strip()
            yaml_keys.add(key)
    
    return yaml_keys

def main():
    print("=== 检查ARB文件中未在映射文件中定义的键 ===\n")
    
    # 加载两个文件的键
    arb_keys = load_arb_keys()
    yaml_keys = load_yaml_mapping_keys()
    
    if not arb_keys or not yaml_keys:
        return
    
    print(f"ARB文件中的键数量: {len(arb_keys)}")
    print(f"YAML映射文件中的键数量: {len(yaml_keys)}")
    
    # 找出在ARB中但不在YAML映射中的键
    unmapped_keys = arb_keys - yaml_keys
    
    # 找出在YAML映射中但不在ARB中的键
    unused_mapped_keys = yaml_keys - arb_keys
    
    print(f"\n=== 结果 ===")
    
    if unmapped_keys:
        print(f"\n❌ 在ARB文件中存在但在映射文件中未定义的键 ({len(unmapped_keys)}个):")
        for key in sorted(unmapped_keys):
            print(f"  - {key}")
    else:
        print(f"\n✅ 所有ARB文件中的键都在映射文件中有定义")
    
    if unused_mapped_keys:
        print(f"\n⚠️  在映射文件中定义但不在ARB文件中的键 ({len(unused_mapped_keys)}个):")
        print("   (这些可能是已删除的未使用键或被替换的键)")
        # 只显示前20个，避免输出过长
        for key in sorted(list(unused_mapped_keys)[:20]):
            print(f"  - {key}")
        if len(unused_mapped_keys) > 20:
            print(f"  ... 还有 {len(unused_mapped_keys) - 20} 个键未显示")
    
    print(f"\n=== 统计摘要 ===")
    print(f"ARB文件键数: {len(arb_keys)}")
    print(f"映射文件键数: {len(yaml_keys)}")
    print(f"未映射的ARB键: {len(unmapped_keys)}")
    print(f"未使用的映射键: {len(unused_mapped_keys)}")
    print(f"重叠键数: {len(arb_keys & yaml_keys)}")

if __name__ == "__main__":
    main()
