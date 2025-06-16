#!/usr/bin/env python3
"""
ARB Mapping Generator

This script analyzes ARB files and creates a YAML mapping file that shows:
1. All keys with their values
2. Which keys can replace other keys (with similar values)
3. Which keys are unique and should be preserved

The YAML file can be manually edited by users to customize the mapping.
"""

import os
import json
import yaml
import re
import difflib
from collections import defaultdict, OrderedDict
import datetime

# Constants
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
REPORT_DIR = "arb_report"
YAML_MAPPING_PATH = os.path.join(REPORT_DIR, "key_mapping.yaml")

# Create report directory if it doesn't exist
os.makedirs(REPORT_DIR, exist_ok=True)

def load_arb_files():
    """Load ARB files and return their data"""
    with open(ZH_ARB_PATH, 'r', encoding='utf-8') as f:
        zh_data = json.load(f, object_pairs_hook=OrderedDict)
    
    with open(EN_ARB_PATH, 'r', encoding='utf-8') as f:
        en_data = json.load(f, object_pairs_hook=OrderedDict)
    
    # Filter out metadata entries (starting with @)
    zh_keys = {k: v for k, v in zh_data.items() if not k.startswith("@")}
    en_keys = {k: v for k, v in en_data.items() if not k.startswith("@")}
    
    return zh_keys, en_keys

def calculate_similarity(s1, s2):
    """Calculate similarity between two strings"""
    if not s1 or not s2:
        return 0.0
    
    # For exact matches, return maximum similarity
    if s1 == s2:
        return 1.0
    
    # Use sequence matcher for string similarity
    return difflib.SequenceMatcher(None, s1, s2).ratio()

def find_similar_values(arb_data, similarity_threshold=0.85):
    """Find keys with similar values and group them"""
    # Group keys by exact same values first
    value_to_keys = defaultdict(list)
    for key, value in arb_data.items():
        value_to_keys[value].append(key)
    
    # Find groups with identical values
    identical_groups = [keys for value, keys in value_to_keys.items() if len(keys) > 1]
    
    # Find similar values
    remaining_keys = set(arb_data.keys())
    for group in identical_groups:
        for key in group:
            if key in remaining_keys:
                remaining_keys.remove(key)
    
    # Calculate similarity between remaining values
    similar_groups = []
    while remaining_keys:
        key = next(iter(remaining_keys))
        remaining_keys.remove(key)
        
        group = [key]
        value = arb_data[key]
        
        # Find similar values
        similar_keys = []
        for other_key in list(remaining_keys):
            other_value = arb_data[other_key]
            similarity = calculate_similarity(value, other_value)
            if similarity >= similarity_threshold:
                similar_keys.append(other_key)
        
        # Add similar keys to group
        for similar_key in similar_keys:
            group.append(similar_key)
            remaining_keys.remove(similar_key)
        
        if len(group) > 1:
            similar_groups.append(group)
    
    return identical_groups + similar_groups

def generate_yaml_mapping():
    """Generate YAML mapping file with values from ARB files"""
    print("Loading ARB files...")
    zh_data, en_data = load_arb_files()
    
    print(f"Loaded {len(zh_data)} keys from Chinese ARB file")
    print(f"Loaded {len(en_data)} keys from English ARB file")
    
    # Find similar values in Chinese
    print("Finding similar values in Chinese ARB file...")
    zh_groups = find_similar_values(zh_data)
    
    # Find similar values in English
    print("Finding similar values in English ARB file...")
    en_groups = find_similar_values(en_data)
    
    # Combine groups from both languages
    print("Combining similar values from both languages...")
    combined_groups = []
    
    # First, add groups that are similar in both languages
    for zh_group in zh_groups:
        for en_group in en_groups:
            if len(set(zh_group) & set(en_group)) > 0:
                # If there's an overlap, merge the groups
                combined_group = list(set(zh_group) | set(en_group))
                combined_groups.append(combined_group)
                break
        else:
            # If no overlap with any English group, add the Chinese group
            combined_groups.append(zh_group)
    
    # Add remaining English groups that don't overlap with any Chinese group
    for en_group in en_groups:
        if not any(len(set(en_group) & set(group)) > 0 for group in combined_groups):
            combined_groups.append(en_group)
    
    # Create the YAML mapping
    print("Creating YAML mapping...")
    yaml_data = OrderedDict()
    processed_keys = set()
    
    # Add groups with replacements
    for group in combined_groups:
        # Sort keys by length (shorter keys are generally better)
        sorted_keys = sorted(group, key=lambda k: (len(k.split('_')), len(k)))
        primary_key = sorted_keys[0]
        processed_keys.update(group)
        
        # Add primary key with its values
        yaml_data[primary_key] = {
            'zh': zh_data.get(primary_key, ""),
            'en': en_data.get(primary_key, ""),
            'replaces': sorted_keys[1:] if len(sorted_keys) > 1 else []
        }
    
    # Add remaining keys (unique keys)
    all_keys = set(zh_data.keys()) | set(en_data.keys())
    remaining_keys = all_keys - processed_keys
    
    for key in sorted(remaining_keys):
        yaml_data[key] = {
            'zh': zh_data.get(key, ""),
            'en': en_data.get(key, ""),
            'replaces': []
        }
    
    # Write the YAML file
    with open(YAML_MAPPING_PATH, 'w', encoding='utf-8') as f:
        # Add header comments
        f.write("# ARB Key Mapping File\n")
        f.write("# Generated on: " + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S") + "\n")
        f.write("# \n")
        f.write("# This file shows all ARB keys and their values, along with information about\n")
        f.write("# which keys can replace other keys (due to similar values).\n")
        f.write("# \n")
        f.write("# You can edit this file to customize the key mapping:\n")
        f.write("# 1. Change the primary key names if needed\n")
        f.write("# 2. Move keys between the 'replaces' lists\n")
        f.write("# 3. Remove keys from 'replaces' lists to keep them as separate keys\n")
        f.write("# \n")
        f.write("# After editing, run the apply_yaml_mapping.py script to generate new ARB files.\n")
        f.write("# \n")
        
        # Write the YAML data
        yaml.dump(yaml_data, f, allow_unicode=True, sort_keys=False, width=1000)
    
    print(f"Generated YAML mapping file: {YAML_MAPPING_PATH}")
    print(f"Found {len(combined_groups)} groups of similar keys")
    print(f"Total unique keys after optimization: {len(yaml_data)}")
    print(f"Total keys before optimization: {len(all_keys)}")
    print(f"Reduction: {len(all_keys) - len(yaml_data)} keys ({round((len(all_keys) - len(yaml_data)) / len(all_keys) * 100, 1)}%)")

if __name__ == "__main__":
    print("=== ARB Mapping Generator ===")
    generate_yaml_mapping()
    print("\nYAML mapping file generated successfully!")
    print(f"Please review and edit {YAML_MAPPING_PATH} as needed.")
    print("Then run apply_yaml_mapping.py to generate new ARB files.")
