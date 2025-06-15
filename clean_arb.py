#!/usr/bin/env python3
import json
import os
from collections import OrderedDict

def clean_arb_file(filepath):
    """清理ARB文件中的重复键，保留第一个出现的键"""
    print(f"正在清理 {filepath}...")
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 使用OrderedDict保持顺序并自动去重
    try:
        # 首先尝试直接解析JSON
        data = json.loads(content, object_pairs_hook=OrderedDict)
        
        # 重新写入文件
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ {filepath} 清理完成")
        return True
        
    except json.JSONDecodeError as e:
        print(f"❌ JSON解析错误: {e}")
        return False

def main():
    base_dir = "lib/l10n"
    
    # 清理两个ARB文件
    for filename in ["app_zh.arb", "app_en.arb"]:
        filepath = os.path.join(base_dir, filename)
        if os.path.exists(filepath):
            clean_arb_file(filepath)
        else:
            print(f"❌ 文件不存在: {filepath}")

if __name__ == "__main__":
    main()
