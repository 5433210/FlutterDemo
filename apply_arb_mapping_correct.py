#!/usr/bin/env python3
"""
CORRECTLY Fixed apply ARB mapping with proper YAML understanding.
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
    """Load the YAML mapping file with correct understanding of the format"""
    
    if not os.path.exists(KEY_MAPPING_YAML_PATH):
        print(f"Error: YAML mapping file {KEY_MAPPING_YAML_PATH} not found!")
        return None
    
    key_mapping = {}
    replacing_keys = {}
    unused_keys = set()
    key_values = {}  # Store key -> value mapping from YAML
    
    current_main_key = None
    is_replacement_section = False
    is_unused_section = False
    
    with open(KEY_MAPPING_YAML_PATH, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    for line_num, line in enumerate(lines, 1):
        original_line = line
        line = line.strip()
        if not line:
            continue
        
        # Check for section markers in comments
        if line.startswith('# 以下键替代了其他键'):
            is_replacement_section = True
            is_unused_section = False
            continue
        elif line.startswith('# 以下是普通键') or line.startswith('# 未替代其他键'):
            is_replacement_section = False
            is_unused_section = False
            continue
        elif line.startswith('# 以下是未使用的键'):
            is_replacement_section = False
            is_unused_section = True
            continue
        elif line.startswith('#'):
            # Skip other comment lines
            continue        # Check if this is a main key (not indented)
        if not original_line.startswith(' ') and not original_line.startswith('\t'):
            if ': ' in line:
                key, value = line.split(': ', 1)
                key = key.strip()
                value = value.strip()
                
                current_main_key = key
                key_values[key] = value  # Store the value from YAML
                
                if is_unused_section:
                    unused_keys.add(key)
                    key_mapping[key] = key
                else:
                    # For both replacement and normal sections, treat as replacement key
                    replacing_keys[key] = []
                    key_mapping[key] = key  # Map to itself initially
        
        # Check if this is an indented key
        elif (original_line.startswith(' ') or original_line.startswith('\t')) and current_main_key:
            if ': ' in line:
                key, value = line.split(': ', 1)
                key = key.strip()
                value = value.strip()                
                if is_unused_section and key != current_main_key:
                    # This is also an unused key
                    unused_keys.add(key)
                    key_mapping[key] = key
                    key_values[key] = value  # Store the value for unused keys too
                elif not is_unused_section and key != current_main_key:
                    # For both replacement and normal sections, treat indented keys as to be replaced
                    key_mapping[key] = current_main_key
                    replacing_keys[current_main_key].append(key)
                    # Also store the value for the indented key
                    key_values[key] = value
                # If key == current_main_key, it's just a duplicate line, ignore it
    
    print(f"Loaded mapping:")
    print(f"- Total keys in mapping: {len(key_mapping)}")
    print(f"- Replacement keys: {len([k for k in replacing_keys.keys() if replacing_keys[k]])}")
    print(f"- Unused keys: {len(unused_keys)}")
    
    # Show some examples
    print(f"\nFirst 5 replacement examples:")
    count = 0
    for main_key, replaced_list in replacing_keys.items():
        if replaced_list and count < 5:
            print(f"  {main_key} <- {replaced_list}")
            count += 1
    
    return key_mapping, replacing_keys, unused_keys, key_values

def update_arb_files(key_mapping, replacing_keys, unused_keys, key_values, remove_unused=False):
    """Update ARB files based on the key mapping"""
    
    # Load existing ARB data
    with open(ZH_ARB_PATH, 'r', encoding='utf-8') as f:
        zh_data = json.load(f, object_pairs_hook=OrderedDict)
    
    with open(EN_ARB_PATH, 'r', encoding='utf-8') as f:
        en_data = json.load(f, object_pairs_hook=OrderedDict)
    
    original_zh_count = len([k for k in zh_data.keys() if not k.startswith('@')])
    
    # Create new ARB data - DO NOT copy metadata keys
    new_zh_data = OrderedDict()
    new_en_data = OrderedDict()
    
    processed_target_keys = set()
    replaced_count = 0
    removed_unused_count = 0
    
    # Process each key in the original ARB data
    for original_key in zh_data.keys():
        if original_key.startswith('@'):
            continue
            
        # Skip unused keys if requested
        if remove_unused and original_key in unused_keys:
            removed_unused_count += 1
            print(f"Removing unused key: {original_key}")
            continue
            
        # Get target key (where this key should map to)
        target_key = key_mapping.get(original_key, original_key)
        
        if target_key != original_key:
            replaced_count += 1
            print(f"Mapping {original_key} -> {target_key}")
          # Only add if we haven't processed this target key yet
        if target_key not in processed_target_keys:
            # Use the value from YAML if available (user may have modified it)
            if target_key in key_values:
                new_zh_data[target_key] = key_values[target_key]
                new_en_data[target_key] = key_values[target_key]  # Use same value for both languages for now
            elif target_key in zh_data:
                new_zh_data[target_key] = zh_data[target_key]
                new_en_data[target_key] = en_data.get(target_key, zh_data[target_key])
            elif original_key in zh_data:
                new_zh_data[target_key] = zh_data[original_key]
                new_en_data[target_key] = en_data.get(original_key, zh_data[original_key])
                
            processed_target_keys.add(target_key)
      # Write updated ARB files with sorted keys
    def write_sorted_arb(file_path, data):
        """Write ARB file with keys sorted alphabetically"""
        # Separate metadata and content keys
        metadata_keys = OrderedDict()
        content_keys = OrderedDict()
        
        for key, value in data.items():
            if key.startswith('@'):
                metadata_keys[key] = value
            else:
                content_keys[key] = value
        
        # Sort content keys alphabetically (case-insensitive)
        sorted_data = OrderedDict()
        
        # Add metadata keys first (if any)
        for key in sorted(metadata_keys.keys()):
            sorted_data[key] = metadata_keys[key]
        
        # Add sorted content keys
        for key in sorted(content_keys.keys(), key=str.lower):
            sorted_data[key] = content_keys[key]
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(sorted_data, f, ensure_ascii=False, indent=2)
    
    write_sorted_arb(ZH_ARB_PATH, new_zh_data)
    write_sorted_arb(EN_ARB_PATH, new_en_data)
    
    new_zh_count = len(new_zh_data)  # No metadata keys to exclude
    
    print(f"\n=== ARB Files Updated ===")
    print(f"Original key count: {original_zh_count}")
    print(f"New key count: {new_zh_count}")
    print(f"Keys replaced by mapping: {replaced_count}")
    if remove_unused:
        print(f"Unused keys removed: {removed_unused_count}")
    print(f"Total keys reduced by: {original_zh_count - new_zh_count} ({((original_zh_count - new_zh_count) / original_zh_count * 100):.1f}%)")

def update_code_references(key_mapping, unused_keys, remove_unused=False):
    """Update code references to use new key names"""
    dart_files = glob.glob(os.path.join(CODE_DIR, "**", "*.dart"), recursive=True)
    
    updated_files = 0
    total_updates = 0
    
    for dart_file in dart_files:
        try:
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            file_updates = 0
            
            # Update key references
            for old_key, new_key in key_mapping.items():
                if old_key != new_key:
                    patterns = [
                        (rf'AppLocalizations\.of\(context\)\.{re.escape(old_key)}\b', 
                         f'AppLocalizations.of(context).{new_key}'),
                        (rf'l10n\.{re.escape(old_key)}\b', 
                         f'l10n.{new_key}'),
                        (rf'context\.l10n\.{re.escape(old_key)}\b', 
                         f'context.l10n.{new_key}'),
                    ]
                    
                    for pattern, replacement in patterns:
                        matches = re.findall(pattern, content)
                        if matches:
                            content = re.sub(pattern, replacement, content)
                            file_updates += len(matches)
            
            if content != original_content:
                with open(dart_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                updated_files += 1
                total_updates += file_updates
                if file_updates > 0:
                    print(f"Updated {file_updates} references in {dart_file}")
                
        except Exception as e:
            print(f"Error processing {dart_file}: {e}")
    
    print(f"\n=== Code References Updated ===")
    print(f"Files updated: {updated_files}")
    print(f"Total references updated: {total_updates}")

def apply_yaml_mapping(remove_unused=False):
    """Main function to apply YAML mapping"""
    print("=== Applying CORRECTLY Fixed YAML Mapping to ARB Files ===")
    
    # Create backups
    backup_arb_files()
    
    # Load mapping
    result = load_yaml_mapping()
    if result is None:
        return
    
    key_mapping, replacing_keys, unused_keys, key_values = result
    
    if unused_keys:
        if remove_unused:
            print(f"Will remove {len(unused_keys)} unused keys from ARB files")
        else:
            print(f"Found {len(unused_keys)} unused keys (use --remove-unused to remove them)")
      # Update ARB files
    update_arb_files(key_mapping, replacing_keys, unused_keys, key_values, remove_unused)
    
    # Update code references
    update_code_references(key_mapping, unused_keys, remove_unused)
    
    print(f"\n=== Success! ===")
    print(f"ARB files and code references have been updated correctly.")
    print(f"Backup created in: {BACKUP_DIR}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Apply ARB key mapping correctly")
    parser.add_argument("--remove-unused", action="store_true", 
                       help="Remove unused keys from ARB files")
    parser.add_argument("--mapping", type=str, default=KEY_MAPPING_YAML_PATH,
                       help="Path to the YAML mapping file")
    
    args = parser.parse_args()
    
    if args.mapping != KEY_MAPPING_YAML_PATH:
        KEY_MAPPING_YAML_PATH = args.mapping
    
    apply_yaml_mapping(remove_unused=args.remove_unused)
