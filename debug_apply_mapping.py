#!/usr/bin/env python3
"""
Debug version of apply ARB mapping with unused key handling.
"""

import json
import os
import re
import glob
import shutil
import datetime
import argparse
from collections import OrderedDict

# Constants
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
REPORT_DIR = "arb_report"
KEY_MAPPING_YAML_PATH = os.path.join(REPORT_DIR, "custom_key_mapping.yaml")

def debug_load_yaml_mapping():
    """Debug version - Load the YAML mapping file with unused key detection"""
    
    if not os.path.exists(KEY_MAPPING_YAML_PATH):
        print(f"Error: YAML mapping file {KEY_MAPPING_YAML_PATH} not found!")
        return None
    
    # Parse YAML manually to handle the special format with indentation and comments
    key_mapping = {}
    replacing_keys = {}
    unused_keys = set()
    current_replacing_key = None
    is_replacement_section = False
    is_unused_section = False
    
    print(f"Reading file: {KEY_MAPPING_YAML_PATH}")
    
    with open(KEY_MAPPING_YAML_PATH, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    line_count = 0
    for line in lines:
        line_count += 1
        original_line = line
        line = line.strip()
        if not line:
            continue
        
        # Check for section markers in comments
        if line.startswith('# 以下键替代了其他键'):
            is_replacement_section = True
            is_unused_section = False
            print(f"Line {line_count}: Found replacement section marker")
            continue
        elif line.startswith('# 以下是普通键') or line.startswith('# 未替代其他键'):
            is_replacement_section = False
            is_unused_section = False
            print(f"Line {line_count}: Found normal keys section marker")
            continue
        elif line.startswith('# 以下是未使用的键'):
            is_replacement_section = False
            is_unused_section = True
            print(f"Line {line_count}: Found unused keys section marker")
            continue
        elif line.startswith('#'):
            # Skip other comment lines
            continue
        
        # Check if this is a main key (not indented)
        if not line.startswith(' '):
            if ': ' in line:
                key, value = line.split(': ', 1)
                key = key.strip()
                value = value.strip()
                
                # If we're in an unused section, mark this key as unused
                if is_unused_section:
                    unused_keys.add(key)
                    # Still add to mapping for completeness
                    key_mapping[key] = key
                    print(f"Line {line_count}: Added unused key: {key}")
                elif is_replacement_section:
                    current_replacing_key = key
                    replacing_keys[key] = []
                    key_mapping[key] = key  # Map to itself
                    print(f"Line {line_count}: Found replacement key: {key}")
                else:
                    # It's a normal key
                    current_replacing_key = None
                    key_mapping[key] = key  # Map to itself
                    print(f"Line {line_count}: Added normal key: {key}")
        
        # Check if this is a replaced key (indented)
        elif line.startswith(' ') and current_replacing_key and not is_unused_section:
            if ': ' in line:
                key, value = line.split(': ', 1)
                key = key.strip()
                value = value.strip()
                
                # Skip if this is the primary key itself
                if key != current_replacing_key:
                    # This is a replaced key, map it to the current replacing key
                    key_mapping[key] = current_replacing_key
                    replacing_keys[current_replacing_key].append(key)
                    print(f"Line {line_count}: Mapped {key} -> {current_replacing_key}")
                else:
                    print(f"Line {line_count}: Skipped self-reference: {key}")
    
    print(f"\nSummary:")
    print(f"Total keys in mapping: {len(key_mapping)}")
    print(f"Replacement keys: {len([k for k in replacing_keys.keys() if replacing_keys[k]])}")
    print(f"Unused keys: {len(unused_keys)}")
    
    print(f"\nFirst 5 replacement keys:")
    count = 0
    for key, replaced_list in replacing_keys.items():
        if replaced_list and count < 5:
            print(f"  {key} replaces: {replaced_list}")
            count += 1
    
    return key_mapping, replacing_keys, unused_keys

if __name__ == "__main__":
    debug_load_yaml_mapping()
