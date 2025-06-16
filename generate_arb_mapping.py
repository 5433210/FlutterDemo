#!/usr/bin/env python3
"""
Generate a clean, human-readable YAML key mapping file from ARB files.
The mapping shows which keys replace others and their values,
allowing users to manually edit the mapping before applying changes.
"""

import json
import os
import re
import glob
import yaml
from collections import OrderedDict, defaultdict

# Constants
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
REPORT_DIR = "arb_report"
KEY_MAPPING_YAML_PATH = os.path.join(REPORT_DIR, "key_mapping.yaml")

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

def generate_mapping_yaml():
    """Generate a human-readable YAML mapping file"""
    os.makedirs(REPORT_DIR, exist_ok=True)
    
    # Load ARB data
    zh_data, en_data = load_arb_files()
    
    # Find similar keys in both language files
    zh_similar = find_similar_keys(zh_data)
    en_similar = find_similar_keys(en_data)
    
    # Create mapping for keys with identical values
    replacement_mapping = {}
    replaced_keys = set()
    
    # Process Chinese similar keys
    for value, keys in zh_similar.items():
        # Check if these keys also have identical values in English
        if all(key in en_data for key in keys) and len(set(en_data[key] for key in keys)) == 1:
            # Sort keys by length (prefer shorter keys) and alphabet
            sorted_keys = sorted(keys, key=lambda k: (len(k), k))
            primary_key = sorted_keys[0]
            
            for secondary_key in sorted_keys[1:]:
                replacement_mapping[secondary_key] = primary_key
                replaced_keys.add(secondary_key)
    
    # Create the YAML content with exact formatting as requested
    yaml_content = "# ARB Key Mapping for Optimization\n"
    yaml_content += "# Edit this file to customize key replacements\n"
    yaml_content += "# Format: key: value  # Comment\n\n"
    
    # Get all keys that replace others (primary keys)
    replacing_keys = set(replacement_mapping.values())
    
    # Group replaced keys by their replacer
    replacer_to_replaced = {}
    for replaced, replacer in replacement_mapping.items():
        if replacer not in replacer_to_replaced:
            replacer_to_replaced[replacer] = []
        replacer_to_replaced[replacer].append(replaced)
      # First output keys that replace others with their replaced keys indented underneath
    for key in sorted(replacing_keys):
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
      # Then output normal keys (not involved in replacements)
    normal_keys = set(k for k in zh_data.keys() if not k.startswith('@') 
                     and k not in replacing_keys and k not in replaced_keys)
    
    for key in sorted(normal_keys):
        value = zh_data.get(key, "")
        yaml_content += f"{key}: {value} #没有替代其他key的\n"
        yaml_content += f"   {key}: {value}\n"
        yaml_content += "\n"  # Add empty line between entries
    
    # Write the YAML file
    with open(KEY_MAPPING_YAML_PATH, 'w', encoding='utf-8') as f:
        f.write(yaml_content)
    
    print(f"Generated YAML mapping file: {KEY_MAPPING_YAML_PATH}")
    print(f"Found {len(replacing_keys)} keys that replace others")
    print(f"Found {len(replaced_keys)} keys that are replaced")
    print(f"Found {len(normal_keys)} normal keys")

if __name__ == "__main__":
    print("Generating YAML key mapping file...")
    generate_mapping_yaml()
    print("Done!")
