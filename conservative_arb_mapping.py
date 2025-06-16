#!/usr/bin/env python3
"""
改进的ARB映射生成器 - 更保守的合并策略
此脚本分析ARB文件并生成YAML映射，但采用更保守的合并策略，
避免过度合并具有不同含义或格式的键。
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
KEY_MAPPING_YAML_PATH = os.path.join(REPORT_DIR, "key_mapping_conservative.yaml")

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
    prefix_keys = defaultdict(list)
    
    # Analyze both exact prefixes and word components
    for key in keys:
        # Extract words from key
        words = extract_words_from_key(key)
        
        # Check if first word is a common prefix
        if words and words[0].lower() in COMMON_PREFIXES:
            prefix = words[0].lower()
            prefix_count[prefix] += 1
            prefix_keys[prefix].append(key)
        
        # Check for camelCase prefixes
        for prefix in COMMON_PREFIXES:
            if key.lower().startswith(prefix.lower()) and len(key) > len(prefix):
                # Check if there's a capital letter after the prefix
                if (key[len(prefix)].isupper() or 
                    (len(key) > len(prefix) + 1 and key[len(prefix)] == '_')):
                    prefix_count[prefix] += 1
                    prefix_keys[prefix].append(key)
                    break
    
    return prefix_count, prefix_keys

def standardize_key(key, remove_prefixes=True):
    """Standardize a key by removing common prefixes and converting to a standard format"""
    words = extract_words_from_key(key)
    
    if remove_prefixes and words and words[0].lower() in COMMON_PREFIXES:
        words = words[1:]  # Remove the first word if it's a prefix
    
    # Remove any additional prefixes at the beginning
    while words and words[0].lower() in COMMON_PREFIXES:
        words = words[1:]
    
    if not words:
        return key.lower()  # Fallback to original key if nothing left
    
    # Use camelCase for standardized keys
    result = words[0].lower()
    for word in words[1:]:
        if word:
            result += word[0].upper() + word[1:].lower()
    
    return result

def check_compatible_format(value1, value2):
    """Check if two strings have compatible format for merging"""
    # Check if both contain the same placeholder pattern
    placeholders1 = re.findall(r'\{[a-zA-Z0-9_]+\}', value1)
    placeholders2 = re.findall(r'\{[a-zA-Z0-9_]+\}', value2)
    
    # If one has placeholders and the other doesn't, they're not compatible
    if (placeholders1 and not placeholders2) or (placeholders2 and not placeholders1):
        return False
    
    # If they have different number of placeholders, they're not compatible
    if len(placeholders1) != len(placeholders2):
        return False
    
    # Check for significant structural differences excluding placeholders
    # Replace placeholders with a standard token for comparison
    pattern1 = re.sub(r'\{[a-zA-Z0-9_]+\}', '{X}', value1)
    pattern2 = re.sub(r'\{[a-zA-Z0-9_]+\}', '{X}', value2)
    
    # Calculate similarity of the patterns
    similarity = difflib.SequenceMatcher(None, pattern1, pattern2).ratio()
    
    # If patterns are very different, consider them incompatible
    return similarity > 0.6

def generate_semantic_categories(zh_data):
    """Generate semantic categories for keys based on their values"""
    categories = defaultdict(list)
    
    # Define improved semantic category patterns
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

def suggest_key_standardization(key, prefix_count):
    """Suggest a standardized key name based on analysis"""
    words = extract_words_from_key(key)
    
    # Identify probable prefix
    probable_prefix = None
    if words and words[0].lower() in COMMON_PREFIXES:
        probable_prefix = words[0].lower()
    
    # Check if this prefix is used a lot
    is_common_prefix = probable_prefix and prefix_count.get(probable_prefix, 0) > 5
    
    # Suggest standardized key
    if is_common_prefix:
        # Remove the prefix for suggestion
        standardized = standardize_key(key, remove_prefixes=True)
    else:
        # Keep the prefix but standardize format
        standardized = standardize_key(key, remove_prefixes=False)
    
    return standardized, probable_prefix, is_common_prefix

def has_parameter_differences(key1, key2, zh_data, en_data):
    """Check if keys have different parameter formats or contexts"""
    value1_zh = zh_data.get(key1, "")
    value2_zh = zh_data.get(key2, "")
    value1_en = en_data.get(key1, "")
    value2_en = en_data.get(key2, "")
    
    # Check if format is compatible in both languages
    if not check_compatible_format(value1_zh, value2_zh) or not check_compatible_format(value1_en, value2_en):
        return True
    
    # Get parameters in zh version
    params1_zh = set(re.findall(r'\{([a-zA-Z0-9_]+)\}', value1_zh))
    params2_zh = set(re.findall(r'\{([a-zA-Z0-9_]+)\}', value2_zh))
    
    # Get parameters in en version
    params1_en = set(re.findall(r'\{([a-zA-Z0-9_]+)\}', value1_en))
    params2_en = set(re.findall(r'\{([a-zA-Z0-9_]+)\}', value2_en))
    
    # Check if parameter names are different
    if params1_zh != params2_zh or params1_en != params2_en:
        return True
    
    return False

def can_keys_be_merged(key1, key2, zh_data, en_data):
    """Determine if two keys can be safely merged"""
    # If the values are identical in both languages, they can be merged
    if (zh_data.get(key1) == zh_data.get(key2) and 
        en_data.get(key1) == en_data.get(key2)):
        return True
    
    # Don't merge keys with parameters unless they have identical parameters
    if has_parameter_differences(key1, key2, zh_data, en_data):
        return False
    
    # Don't merge if one is much longer than the other (likely different purpose)
    val1_zh = zh_data.get(key1, "")
    val2_zh = zh_data.get(key2, "")
    length_ratio = max(len(val1_zh), len(val2_zh)) / (min(len(val1_zh), len(val2_zh)) or 1)
    if length_ratio > 1.5:  # One is 50% longer than the other
        return False
    
    # Check if they have the same core meaning
    words1 = extract_words_from_key(key1)
    words2 = extract_words_from_key(key2)
    
    # If the keys share common words and have similar values
    common_words = set(words1) & set(words2)
    if not common_words:
        return False
    
    # Final similarity check for values
    zh_similarity = difflib.SequenceMatcher(None, val1_zh, val2_zh).ratio()
    en_similarity = difflib.SequenceMatcher(None, 
                                          en_data.get(key1, ""), 
                                          en_data.get(key2, "")).ratio()
    
    # Require high similarity in both languages to merge
    return zh_similarity > 0.8 and en_similarity > 0.8

def generate_conservative_mapping():
    """Generate a YAML mapping file with a conservative merging strategy"""
    os.makedirs(REPORT_DIR, exist_ok=True)
    
    # Load ARB data
    zh_data, en_data = load_arb_files()
    
    # Find keys with identical values
    zh_identical = find_identical_values(zh_data)
    
    # Get all valid keys (not metadata)
    all_keys = [k for k in zh_data.keys() if not k.startswith('@')]
    
    # Analyze key prefixes
    prefix_count, prefix_keys = analyze_key_prefixes(all_keys)
    
    # Generate semantic categories
    semantic_categories = generate_semantic_categories(zh_data)
    
    # Create mapping for keys with identical values
    replacement_mapping = {}
    replaced_keys = set()
    
    # Process keys with identical values first (safe to merge)
    for value, keys in zh_identical.items():
        # Verify identical values in both languages
        if all(key in en_data for key in keys) and len(set(en_data[key] for key in keys)) == 1:
            # Suggest standardized key names
            standardized_options = []
            for key in keys:
                std_key, prefix, is_common = suggest_key_standardization(key, prefix_count)
                # Give preference to keys without common prefixes
                standardized_options.append((key, std_key, prefix, is_common))
            
            # Sort options prioritizing keys without common prefixes and shorter names
            standardized_options.sort(key=lambda x: (1 if x[3] else 0, len(x[0])))
            
            # Choose the best key as primary
            if standardized_options:
                primary_key = standardized_options[0][0]
                for secondary_key in keys:
                    if secondary_key != primary_key:
                        replacement_mapping[secondary_key] = primary_key
                        replaced_keys.add(secondary_key)
    
    # Look for semantically similar keys, but be very conservative
    potential_merges = []
    
    # Use a more limited approach focusing on keys with same root but different prefixes
    for prefix, keys_with_prefix in prefix_keys.items():
        # Group by core meaning after removing prefix
        core_meanings = defaultdict(list)
        for key in keys_with_prefix:
            std_key = standardize_key(key, remove_prefixes=True)
            core_meanings[std_key].append(key)
        
        # Check each group of potentially similar keys
        for std_key, similar_keys in core_meanings.items():
            if len(similar_keys) < 2:
                continue
                
            # Find mergeable keys within this group
            for i, key1 in enumerate(similar_keys):
                if key1 in replaced_keys or key1 in replacement_mapping.values():
                    continue
                    
                mergeable_keys = [key1]
                
                for j in range(i+1, len(similar_keys)):
                    key2 = similar_keys[j]
                    if key2 in replaced_keys or key2 in replacement_mapping:
                        continue
                        
                    # Only merge if they can safely be merged
                    if can_keys_be_merged(key1, key2, zh_data, en_data):
                        mergeable_keys.append(key2)
                
                # If we found mergeable keys, add them to potential merges
                if len(mergeable_keys) > 1:
                    potential_merges.append(mergeable_keys)
    
    # Process potential merges
    for merge_group in potential_merges:
        # Sort to find the best primary key (prefer shorter, non-prefixed keys)
        primary_candidates = [(key, standardize_key(key, remove_prefixes=True)) for key in merge_group]
        primary_candidates.sort(key=lambda x: (len(x[0]), x[0]))
        
        primary_key = primary_candidates[0][0]
        
        # Add to replacement mapping
        for key in merge_group:
            if key != primary_key:
                replacement_mapping[key] = primary_key
                replaced_keys.add(key)
    
    # Create the YAML content with improved organization
    yaml_content = "# ARB Key Mapping for Optimization\n"
    yaml_content += "# 编辑此文件来自定义键值替换 (保守合并版本)\n"
    yaml_content += "# 格式说明:\n"
    yaml_content += "# 替代型键值格式:\n"
    yaml_content += "# # 以下键替代了其他键\n"
    yaml_content += "# key: value\n"
    yaml_content += "#    key: value\n"
    yaml_content += "#    replaced_key1: value1\n"
    yaml_content += "#    replaced_key2: value2\n"
    yaml_content += "# \n"
    yaml_content += "# 普通键值格式:\n"
    yaml_content += "# # 以下是普通键\n"
    yaml_content += "# key: value\n"
    yaml_content += "#    key: value\n\n"
    
    # Add analysis summary
    yaml_content += "# === 分析摘要 ===\n"
    yaml_content += f"# 总键数: {len(all_keys)}\n"
    yaml_content += f"# 具有相同值的键: {sum(len(keys) for keys in zh_identical.values()) - len(zh_identical)}\n"
    yaml_content += f"# 建议合并的键组: {len(potential_merges)}\n"
    yaml_content += f"# 常见前缀: {', '.join(f'{p}({c})' for p, c in sorted(prefix_count.items(), key=lambda x: x[1], reverse=True)[:10])}\n\n"
    
    # Get all keys that replace others (primary keys)
    replacing_keys = set(replacement_mapping.values())
    
    # Group replaced keys by their replacer
    replacer_to_replaced = {}
    for replaced, replacer in replacement_mapping.items():
        if replacer not in replacer_to_replaced:
            replacer_to_replaced[replacer] = []
        replacer_to_replaced[replacer].append(replaced)
    
    # Sort keys by semantic categories for better organization    yaml_content += "# === 按语义类别分组的键 ===\n"
    
    # Organize output by semantic categories
    for category, cat_keys in sorted(semantic_categories.items()):
        replacing_in_category = [k for k in cat_keys if k in replacing_keys]
        normal_in_category = [k for k in cat_keys if k not in replacing_keys and k not in replaced_keys]
        
        if replacing_in_category or normal_in_category:
            yaml_content += f"\n# --- {category.upper()} ({len(replacing_in_category) + len(normal_in_category)} 键) ---\n\n"
              # First output keys that replace others in this category
            for key in sorted(replacing_in_category):
                if key in replacer_to_replaced:
                    value = zh_data.get(key, "")
                    yaml_content += f"# 以下键替代了其他键\n"
                    yaml_content += f"{key}: {value}\n"
                      # Add the primary key itself first without comments
                    yaml_content += f"   {key}: {value}\n"
                    
                    # Add indented replaced keys without comments
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
                yaml_content += "\n"  # Add empty line between entries
    
    # Add improved suggestions for prefix standardization
    yaml_content += "\n# === 前缀分析与标准化建议 ===\n"
    yaml_content += "# 以下部分显示了按常见前缀分组的键名。\n"
    yaml_content += "# 考虑移除不必要的前缀并标准化键名。\n\n"
    
    for prefix, count in sorted(prefix_count.items(), key=lambda x: x[1], reverse=True):
        if count >= 5:  # Only show prefixes with significant usage
            yaml_content += f"# --- {prefix} 前缀 ({count} 键) ---\n"
            
            # Show examples with standardization suggestions
            for key in sorted(prefix_keys[prefix])[:10]:
                value = zh_data.get(key, "")
                standardized, _, _ = suggest_key_standardization(key, prefix_count)
                yaml_content += f"# {key}: {value} -> 建议: '{standardized}'\n"
            
            if len(prefix_keys[prefix]) > 10:
                yaml_content += f"# ... 另有 {len(prefix_keys[prefix]) - 10} 个带有 '{prefix}' 前缀的键\n"
            
            yaml_content += "\n"
    
    # Write the YAML file
    with open(KEY_MAPPING_YAML_PATH, 'w', encoding='utf-8') as f:
        f.write(yaml_content)
    
    print(f"生成保守版YAML映射文件: {KEY_MAPPING_YAML_PATH}")
    print(f"找到 {len(replacing_keys)} 个替代其他键的键")
    print(f"找到 {len(replaced_keys)} 个被替代的键")
    print(f"识别出 {len(prefix_count)} 个常见前缀")
    print(f"将键分组为 {len(semantic_categories)} 个语义类别")

if __name__ == "__main__":
    print("正在生成保守版YAML键映射文件...")
    generate_conservative_mapping()
    print("完成!")
