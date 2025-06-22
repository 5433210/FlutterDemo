#!/usr/bin/env python3
"""
Super Enhanced ARB Mapping Generator with advanced prefix analysis and semantic grouping.
This script analyzes ARB files and generates a YAML mapping with:
- Improved sorting and categorization of keys
- Advanced prefix detection and removal logic
- Smart key merger suggestions based on semantic meaning
- Better visualization for manual review and editing
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

# Common module prefixes to analyze
COMMON_PREFIXES = [
    "work", "character", "practice", "filter", "setting", "library", 
    "collection", "property", "panel", "form", "detail", "edit", "page",
    "dialog", "button", "text", "menu", "app", "ui", "screen", "view",
    "image", "file", "window", "action", "notification", "alert", "list", 
    "item", "section", "tool", "help", "user", "account", "profile"
]

# Semantic word clusters for grouping similar meanings
SEMANTIC_CLUSTERS = {
    "add": ["add", "create", "new", "insert", "attach"],
    "delete": ["delete", "remove", "erase", "clear", "drop"],
    "edit": ["edit", "modify", "change", "update", "revise"],
    "save": ["save", "store", "backup", "preserve"],
    "cancel": ["cancel", "abort", "stop", "dismiss"],
    "confirm": ["confirm", "accept", "yes", "ok", "apply"],
    "close": ["close", "exit", "shut", "end"],
    "open": ["open", "load", "start", "begin"],
    "search": ["search", "find", "query", "lookup"],
    "select": ["select", "choose", "pick", "specify"],
    "move": ["move", "drag", "shift", "reposition"],
    "resize": ["resize", "scale", "adjust", "stretch"],
    "color": ["color", "shade", "hue", "tint"],
    "size": ["size", "dimension", "length", "width", "height"],
    "position": ["position", "location", "place", "coordinate"],
    "error": ["error", "fail", "fault", "bug", "issue"],
    "success": ["success", "complete", "finish", "done"],
    "warning": ["warning", "alert", "caution", "notice"],
    "info": ["info", "information", "description", "detail"],
    "setting": ["setting", "configuration", "option", "preference"],
    "help": ["help", "guide", "assistance", "support", "tip"],
    "share": ["share", "export", "publish", "distribute"],
    "import": ["import", "upload", "receive", "input"],
    "view": ["view", "display", "show", "present"],
    "hide": ["hide", "conceal", "invisible", "obscure"],
    "enable": ["enable", "activate", "turn on", "permit"],
    "disable": ["disable", "deactivate", "turn off", "prohibit"],
    "sort": ["sort", "order", "arrange", "organize"]
}

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

def get_key_core_concept(key):
    """Get the core concept of a key by analyzing its component words"""
    words = extract_words_from_key(key)
    
    # Find semantic concepts in the key
    semantic_concepts = []
    for word in words:
        for concept, related_words in SEMANTIC_CLUSTERS.items():
            if word in related_words or word == concept:
                semantic_concepts.append(concept)
                break
    
    if semantic_concepts:
        return "-".join(semantic_concepts)
    elif words:
        # Use the last non-prefix word as the core concept
        for word in reversed(words):
            if word.lower() not in COMMON_PREFIXES:
                return word
        return words[-1]  # Last word as fallback
    else:
        return key  # Fallback to the original key

def analyze_key_prefixes(keys):
    """Advanced analysis of key names to identify common prefixes and their frequency"""
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

def find_semantically_similar_keys(keys, zh_data, en_data):
    """Find keys that have similar semantic meaning beyond exact value matches"""
    similarity_groups = defaultdict(list)
    
    # Calculate semantic similarity between key pairs
    for key1, key2 in combinations(keys, 2):
        # Skip if either key starts with @
        if key1.startswith('@') or key2.startswith('@'):
            continue
        
        # Skip if they already have the same value
        if zh_data.get(key1) == zh_data.get(key2) and en_data.get(key1) == en_data.get(key2):
            continue
        
        # Get core concepts for both keys
        concept1 = get_key_core_concept(key1)
        concept2 = get_key_core_concept(key2)
        
        # Calculate string similarity between values
        zh_similarity = difflib.SequenceMatcher(None, zh_data.get(key1, ""), zh_data.get(key2, "")).ratio()
        en_similarity = difflib.SequenceMatcher(None, en_data.get(key1, ""), en_data.get(key2, "")).ratio()
        
        # If core concepts match or values are similar, group them
        if (concept1 == concept2 and concept1 != key1 and concept2 != key2) or (zh_similarity > 0.7 and en_similarity > 0.7):
            group_key = concept1 if concept1 == concept2 else f"{key1}_{key2}_similar"
            similarity_groups[group_key].append(key1)
            similarity_groups[group_key].append(key2)
    
    # Clean up groups to ensure each key appears in only one group
    # and ensure groups have at least 2 unique keys
    result = {}
    processed_keys = set()
    
    for group_key, keys_in_group in similarity_groups.items():
        unique_keys = [k for k in keys_in_group if k not in processed_keys]
        if len(unique_keys) >= 2:
            result[group_key] = unique_keys
            processed_keys.update(unique_keys)
    
    return result

def generate_semantic_categories(zh_data):
    """Generate improved semantic categories for keys based on their values and names"""
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

def generate_mapping_yaml():
    """Generate an improved human-readable YAML mapping file with advanced organization"""
    os.makedirs(REPORT_DIR, exist_ok=True)
    
    # Load ARB data
    zh_data, en_data = load_arb_files()
    
    # Find similar keys with identical values
    zh_similar = find_similar_keys(zh_data)
    
    # Get all valid keys (not metadata)
    all_keys = [k for k in zh_data.keys() if not k.startswith('@')]
    
    # Analyze key prefixes
    prefix_count, prefix_keys = analyze_key_prefixes(all_keys)
    
    # Find semantically similar keys (beyond identical values)
    semantic_similar = find_semantically_similar_keys(all_keys, zh_data, en_data)
    
    # Generate semantic categories
    semantic_categories = generate_semantic_categories(zh_data)
    
    # Create mapping for keys with identical values first
    replacement_mapping = {}
    replaced_keys = set()
    
    # Process keys with identical values
    for value, keys in zh_similar.items():
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
    
    # Now process semantically similar keys
    for concept, similar_keys in semantic_similar.items():
        # Skip if these keys are already being processed
        filtered_keys = [k for k in similar_keys if k not in replaced_keys and k not in replacement_mapping]
        if len(filtered_keys) < 2:
            continue
        
        # Suggest standardized key names
        standardized_options = []
        for key in filtered_keys:
            std_key, prefix, is_common = suggest_key_standardization(key, prefix_count)
            standardized_options.append((key, std_key, prefix, is_common))
        
        # Sort options prioritizing keys without common prefixes and shorter names
        standardized_options.sort(key=lambda x: (1 if x[3] else 0, len(x[0])))
        
        # Choose the best key as primary
        if standardized_options:
            primary_key = standardized_options[0][0]
            for secondary_key in filtered_keys:
                if secondary_key != primary_key:
                    replacement_mapping[secondary_key] = primary_key
                    replaced_keys.add(secondary_key)
    
    # Create the YAML content with improved organization
    yaml_content = "# ARB Key Mapping for Optimization\n"
    yaml_content += "# 编辑此文件来自定义键值替换\n"
    yaml_content += "# 格式: key: value  # 注释\n\n"
    
    # Add analysis summary
    yaml_content += "# === 分析摘要 ===\n"
    yaml_content += f"# 总键数: {len(all_keys)}\n"
    yaml_content += f"# 具有相同值的键: {sum(len(keys) for keys in zh_similar.values()) - len(zh_similar)}\n"
    yaml_content += f"# 具有相似语义的键: {sum(len(keys) for keys in semantic_similar.values()) - len(semantic_similar)}\n"
    yaml_content += f"# 常见前缀: {', '.join(f'{p}({c})' for p, c in sorted(prefix_count.items(), key=lambda x: x[1], reverse=True)[:10])}\n\n"
    
    # Get all keys that replace others (primary keys)
    replacing_keys = set(replacement_mapping.values())
    
    # Group replaced keys by their replacer
    replacer_to_replaced = {}
    for replaced, replacer in replacement_mapping.items():
        if replacer not in replacer_to_replaced:
            replacer_to_replaced[replacer] = []
        replacer_to_replaced[replacer].append(replaced)
    
    # Sort keys by semantic categories for better organization
    yaml_content += "# === 按语义类别分组的键 ===\n"
    
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
                    yaml_content += f"{key}: {value} #替代了其他key的\n"
                    
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
                yaml_content += f"{key}: {value} #没有替代其他key的\n"
                yaml_content += f"   {key}: {value}\n"
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
    
    # Add suggestions for semantic grouping
    yaml_content += "\n# === 语义分析与合并建议 ===\n"
    yaml_content += "# 以下是基于语义相似性的键合并建议。\n"
    yaml_content += "# 这些键具有相似的含义，可考虑合并。\n\n"
    
    for concept, similar_keys in semantic_similar.items():
        if len(similar_keys) >= 2:
            # Only show if not already covered by identical values
            unique_keys = [k for k in similar_keys if k not in replaced_keys or k in replacing_keys]
            if len(unique_keys) >= 2:
                yaml_content += f"# --- 相似含义: '{concept}' ---\n"
                
                for key in sorted(unique_keys):
                    value = zh_data.get(key, "")
                    yaml_content += f"# {key}: {value}\n"
                
                # Suggest a standardized name
                suggestions = [suggest_key_standardization(k, prefix_count)[0] for k in unique_keys]
                best_suggestion = min(suggestions, key=len)
                yaml_content += f"# 建议合并为: '{best_suggestion}'\n\n"
    
    # Write the YAML file
    with open(KEY_MAPPING_YAML_PATH, 'w', encoding='utf-8') as f:
        f.write(yaml_content)
    
    print(f"生成增强版YAML映射文件: {KEY_MAPPING_YAML_PATH}")
    print(f"找到 {len(replacing_keys)} 个替代其他键的键")
    print(f"找到 {len(replaced_keys)} 个被替代的键")
    print(f"识别出 {len(prefix_count)} 个常见前缀")
    print(f"将键分组为 {len(semantic_categories)} 个语义类别")
    print(f"识别出 {len(semantic_similar)} 个语义相似的键组")

if __name__ == "__main__":
    print("正在生成增强版YAML键映射文件...")
    generate_mapping_yaml()
    print("完成!")
