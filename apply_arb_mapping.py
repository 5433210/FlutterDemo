#!/usr/bin/env python3
"""
Apply the edited YAML key mapping to ARB files.
This script reads the YAML mapping file and uses it to update ARB files,
replacing old keys with new ones and updating code references.
"""

import json
import os
import re
import glob
import yaml
import shutil
import datetime
from collections import OrderedDict

# Constants
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
REPORT_DIR = "arb_report"
KEY_MAPPING_YAML_PATH = os.path.join(REPORT_DIR, "key_mapping.yaml")
BACKUP_DIR = f"arb_backup_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"
CODE_DIR = "lib"

def backup_arb_files():
    """Create backups of ARB files"""
    os.makedirs(BACKUP_DIR, exist_ok=True)
    
    for arb_file in [ZH_ARB_PATH, EN_ARB_PATH]:
        if os.path.exists(arb_file):
            backup_path = os.path.join(BACKUP_DIR, os.path.basename(arb_file))
            shutil.copy2(arb_file, backup_path)
            print(f"Backed up {arb_file} to {backup_path}")
        else:
            print(f"Warning: ARB file {arb_file} not found!")

def load_yaml_mapping():
    """Load the YAML mapping file"""
    
    if not os.path.exists(KEY_MAPPING_YAML_PATH):
        print(f"Error: YAML mapping file {KEY_MAPPING_YAML_PATH} not found!")
        return None
    
    # Parse YAML manually to handle the special format with indentation and comments
    key_mapping = {}
    replacing_keys = {}
    current_replacing_key = None
    is_replacement_section = False
    
    with open(KEY_MAPPING_YAML_PATH, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        # Check for section markers in comments
        if line.startswith('# 以下键替代了其他键'):
            is_replacement_section = True
            continue
        elif line.startswith('# 以下是普通键') or line.startswith('# 未替代其他键'):
            is_replacement_section = False
            continue
        elif line.startswith('# 原始键值：'):
            # This marks the beginning of the original key values section
            # We keep is_replacement_section unchanged
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
                
                # If we're in a replacement section
                if is_replacement_section:
                    current_replacing_key = key
                    replacing_keys[key] = []
                    key_mapping[key] = key  # Map to itself
                else:
                    # It's a normal key
                    current_replacing_key = None
                    key_mapping[key] = key  # Map to itself
        
        # Check if this is a replaced key (indented)
        elif line.startswith(' ') and current_replacing_key:
            if ': ' in line:
                key, value = line.split(': ', 1)
                key = key.strip()
                value = value.strip()
                
                # Skip if this is the primary key itself
                if key != current_replacing_key:
                    # This is a replaced key, map it to the current replacing key
                    key_mapping[key] = current_replacing_key
                    replacing_keys[current_replacing_key].append(key)
    
    return key_mapping, replacing_keys

def update_arb_files(key_mapping, replacing_keys):
    """Update ARB files based on the key mapping"""
    # Load original ARB data
    with open(ZH_ARB_PATH, 'r', encoding='utf-8') as f:
        zh_data = json.load(f, object_pairs_hook=OrderedDict)
    
    with open(EN_ARB_PATH, 'r', encoding='utf-8') as f:
        en_data = json.load(f, object_pairs_hook=OrderedDict)
    
    # Create new ARB data with optimized keys
    new_zh_data = OrderedDict()
    new_en_data = OrderedDict()
    
    # Copy metadata
    for key, value in zh_data.items():
        if key.startswith('@'):
            new_zh_data[key] = value
    
    for key, value in en_data.items():
        if key.startswith('@'):
            new_en_data[key] = value
    
    # Process all keys in the mapping
    processed_keys = set()
    
    # First add replacing keys
    for key in replacing_keys:
        if key not in processed_keys and key in zh_data and key in en_data:
            # Add the key and its value
            new_zh_data[key] = zh_data[key]
            new_en_data[key] = en_data[key]
            
            # Add metadata if it exists
            metadata_key = f"@{key}"
            if metadata_key in zh_data:
                new_zh_data[metadata_key] = zh_data[metadata_key]
            if metadata_key in en_data:
                new_en_data[metadata_key] = en_data[metadata_key]
            
            processed_keys.add(key)
    
    # Then add normal keys (those that map to themselves)
    for old_key, new_key in key_mapping.items():
        if old_key == new_key and old_key not in processed_keys and old_key in zh_data and old_key in en_data:
            # Add the key and its value
            new_zh_data[old_key] = zh_data[old_key]
            new_en_data[old_key] = en_data[old_key]
            
            # Add metadata if it exists
            metadata_key = f"@{old_key}"
            if metadata_key in zh_data:
                new_zh_data[metadata_key] = zh_data[metadata_key]
            if metadata_key in en_data:
                new_en_data[metadata_key] = en_data[metadata_key]
            
            processed_keys.add(old_key)
    
    # Write updated ARB files
    with open(ZH_ARB_PATH, 'w', encoding='utf-8') as f:
        json.dump(new_zh_data, f, indent=2, ensure_ascii=False)
    
    with open(EN_ARB_PATH, 'w', encoding='utf-8') as f:
        json.dump(new_en_data, f, indent=2, ensure_ascii=False)
    
    print(f"Updated ARB files with {len(processed_keys)} optimized keys")
    
    # Calculate and print stats
    original_key_count = sum(1 for k in zh_data.keys() if not k.startswith('@'))
    new_key_count = sum(1 for k in new_zh_data.keys() if not k.startswith('@'))
    
    print(f"Original key count: {original_key_count}")
    print(f"New key count: {new_key_count}")
    print(f"Reduced by: {original_key_count - new_key_count} keys ({round((1 - new_key_count/original_key_count) * 100, 2)}%)")

def update_code_references(key_mapping):
    """Update code references to use new key names"""
    dart_files = glob.glob(f"{CODE_DIR}/**/*.dart", recursive=True)
    updated_files = 0
    
    # Define patterns to search for
    key_patterns = [
        (r'l10n\.([a-zA-Z0-9_]+)', r'l10n.{}'),
        (r'AppLocalizations\.of\(context\)\.([a-zA-Z0-9_]+)', r'AppLocalizations.of(context).{}'),
        (r'S\.of\(context\)\.([a-zA-Z0-9_]+)', r'S.of(context).{}'),
        (r'S\.current\.([a-zA-Z0-9_]+)', r'S.current.{}'),
        (r'context\.l10n\.([a-zA-Z0-9_]+)', r'context.l10n.{}'),
        (r'AppLocalizations\.instance\.([a-zA-Z0-9_]+)', r'AppLocalizations.instance.{}')
    ]
    
    for file_path in dart_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except UnicodeDecodeError:
            try:
                with open(file_path, 'r', encoding='latin-1') as f:
                    content = f.read()
            except Exception as e:
                print(f"Warning: Could not read file {file_path}: {str(e)}")
                continue
        
        original_content = content
        
        # Apply all key mappings
        for old_key, new_key in key_mapping.items():
            if old_key != new_key:  # Only update if the key changed
                for pattern, replacement_template in key_patterns:
                    old_pattern = pattern.replace("([a-zA-Z0-9_]+)", re.escape(old_key))
                    new_text = replacement_template.format(new_key)
                    content = re.sub(old_pattern, new_text, content)
        
        # Write the file if changed
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            updated_files += 1
    
    print(f"Updated {updated_files} Dart files with new key references")

def apply_yaml_mapping():
    """Apply the YAML mapping to update ARB files and code references"""
    # Backup ARB files
    backup_arb_files()
    
    # Load YAML mapping
    key_mapping, replacing_keys = load_yaml_mapping()
    if not key_mapping:
        return
    
    # Debug output - print a sample of the key mapping
    print(f"Loaded key mapping with {len(key_mapping)} keys")
    print(f"Found {len(replacing_keys)} keys that replace others")
    
    for i, (key, replacement) in enumerate(key_mapping.items()):
        if key != replacement:  # Only show keys that are mapped to something else
            print(f"  Mapping: {key} -> {replacement}")
        if i >= 5:  # Only show the first 5 mappings
            print(f"  ... and {len(key_mapping) - 6} more")
            break
    
    # Update ARB files
    update_arb_files(key_mapping, replacing_keys)
    
    # Update code references
    update_code_references(key_mapping)
    
    print("Successfully applied YAML mapping to ARB files and code references")

if __name__ == "__main__":
    print("Applying YAML mapping to ARB files...")
    apply_yaml_mapping()
    print("Done!")
