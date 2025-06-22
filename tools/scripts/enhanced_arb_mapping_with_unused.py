#!/usr/bin/env python3
"""
增强的ARB映射生成器 - 带未使用键标记
此脚本基于enhanced_arb_mapping.py，增加了标记未使用键的功能
"""

import json
import os
import re
import glob
import difflib
from collections import defaultdict, OrderedDict
from itertools import combinations

# Constants
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
REPORT_DIR = "arb_report"
KEY_MAPPING_YAML_PATH = os.path.join(REPORT_DIR, "key_mapping.yaml")
UNUSED_KEYS_LIST_PATH = os.path.join(REPORT_DIR, "unused_keys_list.txt")

# Common module prefixes to analyze
COMMON_PREFIXES = [
    "work", "character", "practice", "filter", "setting", "library", 
    "collection", "property", "panel", "form", "detail", "edit", "page",
    "dialog", "button", "text", "menu", "app", "ui", "screen", "view",
    "image", "file", "window", "action", "notification", "alert", "list", 
    "item", "section", "tool", "help", "user", "account", "profile"
]

def load_arb_files():
    """Load ARB files and return their data"""
    with open(ZH_ARB_PATH, 'r', encoding='utf-8') as f:
        zh_data = json.load(f)
    
    with open(EN_ARB_PATH, 'r', encoding='utf-8') as f:
        en_data = json.load(f)
    
    return zh_data, en_data

def load_unused_keys():
    """Load the list of unused keys"""
    unused_keys = set()
    if os.path.exists(UNUSED_KEYS_LIST_PATH):
        with open(UNUSED_KEYS_LIST_PATH, 'r', encoding='utf-8') as f:
            unused_keys = set(line.strip() for line in f if line.strip())
    return unused_keys

def find_identical_values(arb_data):
    """Find keys with identical values"""
    value_to_keys = defaultdict(list)
    
    # Group keys by their exact values
    for key, value in arb_data.items():
        if not key.startswith('@'):  # Skip metadata keys
            value_to_keys[value].append(key)
    
    # Filter groups to only include those with multiple keys
    identical_values = {value: keys for value, keys in value_to_keys.items() if len(keys) > 1}
    
    return identical_values

def extract_words_from_key(key):
    """Extract individual words from a camelCase or snake_case key name"""
    # Split by camelCase
    words = re.findall(r'[A-Z]?[a-z0-9]+|[A-Z]+(?=[A-Z]|$)', key)
    
    # Also handle snake_case if present
    result = []
    for word in words:
        if '_' in word:
            result.extend(word.split('_'))
        else:
            result.append(word)
    
    return [w.lower() for w in result if w]

def analyze_key_prefixes(keys):
    """Analyze key names to identify common prefixes and their frequency"""
    prefix_count = defaultdict(int)
    
    for key in keys:
        words = extract_words_from_key(key)
        
        # Check if first word is a common prefix
        if words and words[0].lower() in COMMON_PREFIXES:
            prefix_count[words[0].lower()] += 1
        
        # Check for camelCase prefixes
        for prefix in COMMON_PREFIXES:
            if key.lower().startswith(prefix.lower()) and len(key) > len(prefix):
                if (key[len(prefix)].isupper() or 
                    (len(key) > len(prefix) + 1 and key[len(prefix)] == '_')):
                    prefix_count[prefix] += 1
                    break
    
    return prefix_count

def generate_semantic_categories(zh_data):
    """Generate semantic categories for keys based on their values"""
    categories = defaultdict(list)
    
    # Define semantic category patterns
    semantic_patterns = {
        'button': [r'按钮', r'确定', r'取消', r'提交', r'保存', r'删除', r'编辑', r'添加', r'返回', r'关闭'],
        'label': [r'标签', r'名称', r'标题', r'作者', r'日期', r'时间', r'大小', r'类型', r'属性'],
        'message': [r'成功', r'失败', r'错误', r'警告', r'提示', r'请稍等', r'加载中', r'确认', r'无法'],
        'dialog': [r'对话框', r'弹窗', r'确认', r'提示', r'警告', r'选择'],
        'status': [r'状态', r'已', r'未', r'完成', r'进行中', r'开始', r'结束', r'暂停', r'运行'],
        'navigation': [r'返回', r'前进', r'首页', r'下一步', r'上一步', r'菜单', r'导航', r'页面'],
        'format': [r'格式', r'类型', r'样式', r'模式', r'方式', r'布局', r'排序', r'对齐'],
        'setting': [r'设置', r'配置', r'选项', r'偏好', r'自动', r'默认', r'选择'],
        'common': [r'通用', r'常用', r'默认', r'基本', r'标准'],
        'color': [r'颜色', r'背景', r'前景', r'透明'],
        'size': [r'大小', r'尺寸', r'宽度', r'高度', r'长度', r'比例', r'缩放'],
        'file': [r'文件', r'保存', r'打开', r'导入', r'导出', r'上传', r'下载'],
        'error': [r'错误', r'失败', r'异常', r'崩溃', r'无法', r'问题'],
        'time': [r'时间', r'日期', r'周', r'月', r'年', r'小时', r'分钟', r'秒'],
        'help': [r'帮助', r'提示', r'指南', r'教程', r'说明'],
        'action': [r'操作', r'动作', r'执行', r'运行', r'停止', r'开始']
    }
    
    # Categorize by value content first
    for key, value in zh_data.items():
        if key.startswith('@'):
            continue
            
        # First try to categorize by value content
        assigned = False
        for category, patterns in semantic_patterns.items():
            if any(re.search(pattern, value) for pattern in patterns):
                categories[category].append(key)
                assigned = True
                break
        
        # If not categorized by value, try by key name
        if not assigned:
            words = extract_words_from_key(key)
            for word in words:
                for category, patterns in semantic_patterns.items():
                    if any(re.search(f"^{word}$", pattern, re.IGNORECASE) for pattern in patterns):
                        categories[category].append(key)
                        assigned = True
                        break
                if assigned:
                    break
        
        # Default category if still not assigned
        if not assigned:
            categories['other'].append(key)
    
    return categories

def find_similar_keys(keys, zh_data, en_data):
    """Find keys with similar core meanings"""
    similar_groups = []
    
    # Group keys by core meaning after removing prefixes
    core_meanings = defaultdict(list)
    for key in keys:
        words = extract_words_from_key(key)
        
        # Remove common prefixes
        while words and words[0].lower() in COMMON_PREFIXES:
            words = words[1:]
        
        if words:
            core_meaning = '_'.join(words)
            core_meanings[core_meaning].append(key)
    
    # Find groups with multiple keys
    for core_meaning, key_group in core_meanings.items():
        if len(key_group) > 1:
            # Check if values are similar enough to merge
            zh_values = [zh_data.get(k, "") for k in key_group]
            en_values = [en_data.get(k, "") for k in key_group]
            
            # Simple similarity check
            unique_zh = set(zh_values)
            unique_en = set(en_values)
            
            if len(unique_zh) == 1 and len(unique_en) == 1:
                # All values are identical
                similar_groups.append(key_group)
    
    return similar_groups

def generate_enhanced_mapping():
    """Generate a YAML mapping file with unused key marking"""
    os.makedirs(REPORT_DIR, exist_ok=True)
    
    # Load ARB data and unused keys
    zh_data, en_data = load_arb_files()
    unused_keys = load_unused_keys()
    
    print(f"Loaded {len(unused_keys)} unused keys")
    
    # Find keys with identical values
    zh_identical = find_identical_values(zh_data)
    
    # Get all valid keys (not metadata)
    all_keys = [k for k in zh_data.keys() if not k.startswith('@')]
    
    # Analyze key prefixes
    prefix_count = analyze_key_prefixes(all_keys)
    
    # Generate semantic categories
    semantic_categories = generate_semantic_categories(zh_data)
    
    # Find similar keys
    similar_groups = find_similar_keys(all_keys, zh_data, en_data)
    
    # Create mapping for keys with identical values
    replacement_mapping = {}
    replaced_keys = set()
    
    # Process keys with identical values
    for value, keys in zh_identical.items():
        # Verify identical values in both languages
        if all(key in en_data for key in keys) and len(set(en_data[key] for key in keys)) == 1:
            # Choose the shortest key as primary (unless it's unused)
            primary_key = min(keys, key=len)
            
            # If primary key is unused, try to find a used one
            if primary_key in unused_keys:
                used_keys = [k for k in keys if k not in unused_keys]
                if used_keys:
                    primary_key = min(used_keys, key=len)
            
            for secondary_key in keys:
                if secondary_key != primary_key:
                    replacement_mapping[secondary_key] = primary_key
                    replaced_keys.add(secondary_key)
    
    # Process similar groups
    for group in similar_groups:
        # Choose primary key (prefer used keys)
        used_in_group = [k for k in group if k not in unused_keys]
        if used_in_group:
            primary_key = min(used_in_group, key=len)
        else:
            primary_key = min(group, key=len)
        
        for secondary_key in group:
            if secondary_key != primary_key:
                replacement_mapping[secondary_key] = primary_key
                replaced_keys.add(secondary_key)
    
    # Create the YAML content
    yaml_content = "# ARB Key Mapping for Optimization (with Unused Key Marking)\n"
    yaml_content += "# Edit this file to customize key replacements\n"
    yaml_content += "# Format:\n"
    yaml_content += "# Replacement keys:\n"
    yaml_content += "# # 以下键替代了其他键\n"
    yaml_content += "# key: value\n"
    yaml_content += "#    key: value\n"
    yaml_content += "#    replaced_key1: value1\n"
    yaml_content += "#    replaced_key2: value2\n"
    yaml_content += "# \n"
    yaml_content += "# Normal keys:\n"
    yaml_content += "# # 以下是普通键\n"
    yaml_content += "# key: value\n"
    yaml_content += "#    key: value\n"
    yaml_content += "# \n"
    yaml_content += "# Unused keys:\n"
    yaml_content += "# # 以下是未使用的键\n"
    yaml_content += "# key: value\n"
    yaml_content += "#    key: value\n\n"
    
    # Add analysis summary
    yaml_content += "# === Analysis Summary ===\n"
    yaml_content += f"# Total keys: {len(all_keys)}\n"
    yaml_content += f"# Keys with identical values: {sum(len(keys) for keys in zh_identical.values()) - len(zh_identical)}\n"
    yaml_content += f"# Keys with similar core meaning: {sum(len(group) - 1 for group in similar_groups)}\n"
    yaml_content += f"# Unused keys: {len(unused_keys)}\n"
    yaml_content += f"# Common prefixes: {', '.join(f'{p}({c})' for p, c in sorted(prefix_count.items(), key=lambda x: x[1], reverse=True)[:10])}\n\n"
    
    # Get all keys that replace others (primary keys)
    replacing_keys = set(replacement_mapping.values())
    
    # Group replaced keys by their replacer
    replacer_to_replaced = {}
    for replaced, replacer in replacement_mapping.items():
        if replacer not in replacer_to_replaced:
            replacer_to_replaced[replacer] = []
        replacer_to_replaced[replacer].append(replaced)
    
    # Sort keys by semantic categories for better organization
    yaml_content += "# === Keys by Semantic Categories ===\n"
    
    # Organize output by semantic categories
    for category, cat_keys in sorted(semantic_categories.items()):
        replacing_in_category = [k for k in cat_keys if k in replacing_keys]
        normal_in_category = [k for k in cat_keys if k not in replacing_keys and k not in replaced_keys and k not in unused_keys]
        unused_in_category = [k for k in cat_keys if k in unused_keys and k not in replaced_keys]
        
        if replacing_in_category or normal_in_category or unused_in_category:
            total_in_category = len(replacing_in_category) + len(normal_in_category) + len(unused_in_category)
            yaml_content += f"\n# --- {category.upper()} ({total_in_category} keys) ---\n\n"
            
            # First output keys that replace others in this category
            for key in sorted(replacing_in_category):
                if key in replacer_to_replaced:
                    value = zh_data.get(key, "")
                    yaml_content += f"# 以下键替代了其他键\n"
                    yaml_content += f"{key}: {value}\n"
                    
                    # Add the primary key itself first
                    yaml_content += f"   {key}: {value}\n"
                    
                    # Add indented replaced keys
                    for replaced_key in sorted(replacer_to_replaced[key]):
                        replaced_value = zh_data.get(replaced_key, "")
                        yaml_content += f"   {replaced_key}: {replaced_value}\n"
                    
                    yaml_content += "\n"  # Add empty line between groups
            
            # Then output normal keys in this category
            for key in sorted(normal_in_category):
                value = zh_data.get(key, "")
                yaml_content += f"# 以下是普通键\n"
                yaml_content += f"{key}: {value}\n"
                yaml_content += f"   {key}: {value}\n"
                yaml_content += "\n"  # Add empty line between entries
            
            # Finally output unused keys in this category
            for key in sorted(unused_in_category):
                value = zh_data.get(key, "")
                yaml_content += f"# 以下是未使用的键 [UNUSED]\n"
                yaml_content += f"{key}: {value}\n"
                yaml_content += f"   {key}: {value}\n"
                yaml_content += "\n"  # Add empty line between entries
    
    # Write the YAML file
    with open(KEY_MAPPING_YAML_PATH, 'w', encoding='utf-8') as f:
        f.write(yaml_content)
    
    print(f"Generated YAML mapping file: {KEY_MAPPING_YAML_PATH}")
    print(f"Found {len(replacing_keys)} keys that replace others")
    print(f"Found {len(replaced_keys)} keys that are replaced")
    print(f"Found {len(unused_keys)} unused keys")
    print(f"Identified {len(prefix_count)} common prefixes")
    print(f"Grouped keys into {len(semantic_categories)} semantic categories")

if __name__ == "__main__":
    print("Generating enhanced YAML key mapping with unused key marking...")
    generate_enhanced_mapping()
    print("Done!")
