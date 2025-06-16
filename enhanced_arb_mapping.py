#!/usr/bin/env python3
"""
Enhanced ARB Mapping Generator with prefix analysis and semantic grouping.
This script analyzes ARB files and generates a YAML mapping with:
- Better sorting of keys by categories and meaning
- Analysis of prefix patterns to identify unnecessary prefixes
- Suggestions for merging keys with similar core meanings
"""

import json
import os
import re
import glob
from collections import defaultdict, OrderedDict

# Constants
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
REPORT_DIR = "arb_report"
KEY_MAPPING_YAML_PATH = os.path.join(REPORT_DIR, "key_mapping.yaml")

# Common module prefixes to analyze
COMMON_PREFIXES = [
    "work", "character", "practice", "filter", "setting", "library", 
    "collection", "property", "panel", "form", "detail", "edit", "page",
    "dialog", "button", "text", "menu", "app", "ui", "screen", "view"
]

def load_arb_files():
    """Load ARB files and return their data"""
    with open(ZH_ARB_PATH, 'r', encoding='utf-8') as f:
        zh_data = json.load(f)
    
    with open(EN_ARB_PATH, 'r', encoding='utf-8') as f:
        en_data = json.load(f)
    
    return zh_data, en_data

def find_similar_keys(arb_data):
    """Find keys with identical values"""
    value_to_keys = defaultdict(list)
    
    # Group keys by their values
    for key, value in arb_data.items():
        if not key.startswith('@'):  # Skip metadata keys
            value_to_keys[value].append(key)
    
    # Filter groups to only include those with multiple keys
    similar_keys = {value: keys for value, keys in value_to_keys.items() if len(keys) > 1}
    
    return similar_keys

def analyze_key_prefixes(keys):
    """Analyze key names to identify common prefixes and their frequency"""
    prefix_count = defaultdict(int)
    prefix_keys = defaultdict(list)
    
    # Regular expression to extract potential prefixes
    prefix_pattern = re.compile(r'^([a-zA-Z]+)[A-Z_]')
    
    for key in keys:
        # Extract potential prefix
        match = prefix_pattern.search(key)
        if match:
            prefix = match.group(1).lower()
            if prefix in COMMON_PREFIXES:
                prefix_count[prefix] += 1
                prefix_keys[prefix].append(key)
    
    return prefix_count, prefix_keys

def extract_core_meaning(key):
    """Extract the core meaning of a key by removing common prefixes"""
    # Remove common prefixes from key name
    for prefix in sorted(COMMON_PREFIXES, key=len, reverse=True):
        pattern = re.compile(f"^{prefix}[A-Z_]", re.IGNORECASE)
        if pattern.search(key):
            # Get the part after the prefix
            core = re.sub(pattern, "", key)
            # Make first character lowercase
            if core:
                core = core[0].lower() + core[1:]
                return core
    
    return key

def group_by_core_meaning(keys, zh_data):
    """Group keys by their core meaning after removing prefixes"""
    core_to_keys = defaultdict(list)
    
    for key in keys:
        core = extract_core_meaning(key)
        core_to_keys[core].append(key)
    
    # Only keep groups with multiple keys
    core_groups = {core: keys for core, keys in core_to_keys.items() if len(keys) > 1}
    
    return core_groups

def generate_semantic_categories(zh_data):
    """Generate semantic categories for keys based on their values"""
    categories = defaultdict(list)
    
    # Define some common semantic categories
    semantic_patterns = {
        'button': [r'按钮', r'确定', r'取消', r'提交', r'保存', r'删除', r'编辑', r'添加'],
        'label': [r'标签', r'名称', r'标题', r'作者', r'日期', r'时间', r'大小', r'类型'],
        'message': [r'成功', r'失败', r'错误', r'警告', r'提示', r'请稍等', r'加载中', r'确认'],
        'dialog': [r'对话框', r'弹窗', r'确认', r'提示', r'警告'],
        'status': [r'状态', r'已', r'未', r'完成', r'进行中', r'开始', r'结束', r'暂停'],
        'navigation': [r'返回', r'前进', r'首页', r'下一步', r'上一步', r'菜单', r'导航'],
        'format': [r'格式', r'类型', r'样式', r'模式', r'方式', r'布局', r'排序'],
        'setting': [r'设置', r'配置', r'选项', r'偏好', r'自动', r'默认'],
        'common': [r'通用', r'常用', r'默认', r'基本', r'标准']
    }
    
    for key, value in zh_data.items():
        if key.startswith('@'):
            continue
            
        # Assign key to categories based on value content
        assigned = False
        for category, patterns in semantic_patterns.items():
            if any(re.search(pattern, value) for pattern in patterns):
                categories[category].append(key)
                assigned = True
                break
                
        if not assigned:
            categories['other'].append(key)
    
    return categories

def generate_mapping_yaml():
    """Generate a human-readable YAML mapping file with improved organization"""
    os.makedirs(REPORT_DIR, exist_ok=True)
    
    # Load ARB data
    zh_data, en_data = load_arb_files()
    
    # Find similar keys in both language files
    zh_similar = find_similar_keys(zh_data)
    
    # Analyze key prefixes
    all_keys = [k for k in zh_data.keys() if not k.startswith('@')]
    prefix_count, prefix_keys = analyze_key_prefixes(all_keys)
    
    # Group keys by core meaning
    core_groups = group_by_core_meaning(all_keys, zh_data)
    
    # Generate semantic categories
    semantic_categories = generate_semantic_categories(zh_data)
    
    # Create mapping for keys with identical values
    replacement_mapping = {}
    replaced_keys = set()
    
    # Process Chinese similar keys
    for value, keys in zh_similar.items():
        # Check if these keys also have identical values in English
        if all(key in en_data for key in keys) and len(set(en_data[key] for key in keys)) == 1:
            # First try to pick key without module prefix
            no_prefix_keys = [k for k in keys if not any(k.lower().startswith(p.lower()) for p in COMMON_PREFIXES)]
            
            if no_prefix_keys:
                # Sort by length and alphabet if multiple no-prefix keys exist
                sorted_keys = sorted(no_prefix_keys, key=lambda k: (len(k), k))
                primary_key = sorted_keys[0]
            else:
                # Sort all keys by length and alphabet
                sorted_keys = sorted(keys, key=lambda k: (len(k), k))
                primary_key = sorted_keys[0]
            
            for secondary_key in keys:
                if secondary_key != primary_key:
                    replacement_mapping[secondary_key] = primary_key
                    replaced_keys.add(secondary_key)
    
    # Also suggest merging keys with the same core meaning
    for core, core_keys in core_groups.items():
        if len(core_keys) > 1:
            # Skip if these keys are already being merged based on identical values
            if all(k in replaced_keys or k in replacement_mapping.values() for k in core_keys):
                continue
                
            # Prefer keys without prefix
            no_prefix_keys = [k for k in core_keys if not any(k.lower().startswith(p.lower()) for p in COMMON_PREFIXES)]
            
            if no_prefix_keys:
                preferred_key = sorted(no_prefix_keys, key=lambda k: (len(k), k))[0]
            else:
                preferred_key = sorted(core_keys, key=lambda k: (len(k), k))[0]
            
            # Suggest merging only if values are similar
            for key in core_keys:
                if key != preferred_key and key not in replaced_keys:
                    # Only suggest if values are somewhat similar (you might want to skip this for initial analysis)
                    replacement_mapping[key] = preferred_key
                    replaced_keys.add(key)
    
    # Create the YAML content with improved organization
    yaml_content = "# ARB Key Mapping for Optimization\n"
    yaml_content += "# Edit this file to customize key replacements\n"
    yaml_content += "# Format: key: value  # Comment\n\n"
    
    # Add analysis summary
    yaml_content += "# === Analysis Summary ===\n"
    yaml_content += f"# Total keys: {len(all_keys)}\n"
    yaml_content += f"# Keys with identical values: {sum(len(keys) for keys in zh_similar.values()) - len(zh_similar)}\n"
    yaml_content += f"# Keys with similar core meaning: {sum(len(keys) for keys in core_groups.values()) - len(core_groups)}\n"
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
        normal_in_category = [k for k in cat_keys if k not in replacing_keys and k not in replaced_keys]
        
        if replacing_in_category or normal_in_category:
            yaml_content += f"\n# --- {category.upper()} ({len(replacing_in_category) + len(normal_in_category)} keys) ---\n\n"
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
    
    # Add analysis of prefixes
    yaml_content += "\n# === Prefix Analysis ===\n"
    yaml_content += "# The following sections show keys grouped by common prefixes.\n"
    yaml_content += "# Consider removing unnecessary prefixes and standardizing key names.\n\n"
    
    for prefix, count in sorted(prefix_count.items(), key=lambda x: x[1], reverse=True):
        if count >= 5:  # Only show prefixes with significant usage
            yaml_content += f"# --- {prefix} prefix ({count} keys) ---\n"
            
            # Show a few examples
            for key in sorted(prefix_keys[prefix])[:10]:
                value = zh_data.get(key, "")
                core = extract_core_meaning(key)
                yaml_content += f"# {key}: {value} -> Suggested core: '{core}'\n"
            
            if len(prefix_keys[prefix]) > 10:
                yaml_content += f"# ... and {len(prefix_keys[prefix]) - 10} more keys with '{prefix}' prefix\n"
            
            yaml_content += "\n"
    
    # Write the YAML file
    with open(KEY_MAPPING_YAML_PATH, 'w', encoding='utf-8') as f:
        f.write(yaml_content)
    
    print(f"Generated enhanced YAML mapping file: {KEY_MAPPING_YAML_PATH}")
    print(f"Found {len(replacing_keys)} keys that replace others")
    print(f"Found {len(replaced_keys)} keys that are replaced")
    print(f"Identified {len(prefix_count)} common prefixes")
    print(f"Grouped keys into {len(semantic_categories)} semantic categories")

if __name__ == "__main__":
    print("Generating enhanced YAML key mapping file...")
    generate_mapping_yaml()
    print("Done!")
