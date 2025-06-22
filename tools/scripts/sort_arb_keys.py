#!/usr/bin/env python3
"""
对ARB文件的键进行字母排序并保存
"""

import json
import os
import shutil
import datetime
from collections import OrderedDict

# 文件路径
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
BACKUP_DIR = f"arb_backup_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}_sorted"

def backup_arb_files():
    """创建ARB文件备份"""
    os.makedirs(BACKUP_DIR, exist_ok=True)
    
    for arb_file in [ZH_ARB_PATH, EN_ARB_PATH]:
        if os.path.exists(arb_file):
            backup_path = os.path.join(BACKUP_DIR, os.path.basename(arb_file))
            shutil.copy2(arb_file, backup_path)
            print(f"已备份 {arb_file} 到 {backup_path}")
        else:
            print(f"警告: ARB文件 {arb_file} 不存在!")

def sort_arb_file(file_path, file_name):
    """对单个ARB文件的键进行排序"""
    if not os.path.exists(file_path):
        print(f"错误: 文件 {file_path} 不存在!")
        return False
    
    # 读取原始数据
    with open(file_path, 'r', encoding='utf-8') as f:
        original_data = json.load(f)
    
    print(f"\n处理 {file_name}:")
    print(f"  原始键数量: {len(original_data)}")
    
    # 分离元数据键和内容键
    metadata_keys = {}
    content_keys = {}
    
    for key, value in original_data.items():
        if key.startswith('@'):
            metadata_keys[key] = value
        else:
            content_keys[key] = value
    
    print(f"  元数据键: {len(metadata_keys)}")
    print(f"  内容键: {len(content_keys)}")
    
    # 对内容键进行排序
    sorted_content_keys = OrderedDict()
    for key in sorted(content_keys.keys(), key=str.lower):  # 忽略大小写进行排序
        sorted_content_keys[key] = content_keys[key]
    
    # 组合最终数据：元数据键在前，内容键在后
    final_data = OrderedDict()
    
    # 先添加元数据键（如果有的话）
    for key in sorted(metadata_keys.keys()):
        final_data[key] = metadata_keys[key]
    
    # 再添加排序后的内容键
    final_data.update(sorted_content_keys)
    
    # 写入排序后的文件
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(final_data, f, ensure_ascii=False, indent=2)
    
    print(f"  ✅ 已完成排序")
    
    # 显示排序前后的前几个键的对比
    original_content_keys = [k for k in original_data.keys() if not k.startswith('@')]
    sorted_keys_list = list(sorted_content_keys.keys())
    
    if original_content_keys != sorted_keys_list:
        print(f"  排序前前5个键: {original_content_keys[:5]}")
        print(f"  排序后前5个键: {sorted_keys_list[:5]}")
    else:
        print(f"  键已经是排序状态")
    
    return True

def main():
    print("=== ARB文件键排序工具 ===")
    
    # 创建备份
    backup_arb_files()
    
    # 对两个ARB文件进行排序
    success_count = 0
    
    if sort_arb_file(ZH_ARB_PATH, "app_zh.arb"):
        success_count += 1
    
    if sort_arb_file(EN_ARB_PATH, "app_en.arb"):
        success_count += 1
    
    print(f"\n=== 排序完成 ===")
    print(f"成功处理的文件: {success_count}/2")
    print(f"备份目录: {BACKUP_DIR}")
    
    # 验证排序结果
    print(f"\n=== 验证排序结果 ===")
    for file_path, file_name in [(ZH_ARB_PATH, "中文ARB"), (EN_ARB_PATH, "英文ARB")]:
        if os.path.exists(file_path):
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                content_keys = [k for k in data.keys() if not k.startswith('@')]
                sorted_keys = sorted(content_keys, key=str.lower)
                is_sorted = content_keys == sorted_keys
                print(f"  {file_name}: {'✅ 已排序' if is_sorted else '❌ 未排序'}")

if __name__ == "__main__":
    main()
