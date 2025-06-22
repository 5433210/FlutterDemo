#!/usr/bin/env python3
"""
为ARB文件中未映射的键创建补丁映射
"""

import json
import os

def main():
    # 未映射的键列表
    unmapped_keys = [
        'characterManagementDeleteSelected',
        'filterDatePresetLast7Days', 
        'filterDatePresetLast90Days',
        'filterDatePresetToday',
        'filterDatePresetYesterday',
        'tagsHint'
    ]
    
    # 从ARB文件获取这些键的值
    with open('lib/l10n/app_zh.arb', 'r', encoding='utf-8') as f:
        arb_data = json.load(f)
    
    print("# 补丁：为未映射的键添加到YAML映射文件")
    print("# 请将以下内容添加到 arb_report/custom_key_mapping.yaml 的适当位置\n")
    
    print("# --- UNMAPPED KEYS (补丁) ---\n")
    
    for key in unmapped_keys:
        if key in arb_data:
            value = arb_data[key]
            print(f"# 以下是普通键")
            print(f"{key}: {value}")
            print(f"   {key}: {value}")
            print()
        else:
            print(f"# 警告: 键 '{key}' 在ARB文件中未找到")
    
    print("\n# 建议将这些键按语义分类添加到相应的类别中")
    print("# 例如:")
    print("# - characterManagementDeleteSelected 应该添加到 BUTTON 类别")
    print("# - filterDatePreset* 键应该添加到适当的过滤器类别")
    print("# - tagsHint 应该添加到适当的提示类别")

if __name__ == "__main__":
    main()
