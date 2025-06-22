#!/usr/bin/env python3
"""
Enhanced fixed apply ARB mapping with proper handling of all duplicate keys.
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
    """Load the YAML mapping file with unused key detection - ENHANCED VERSION"""
    
    if not os.path.exists(KEY_MAPPING_YAML_PATH):
        print(f"Error: YAML mapping file {KEY_MAPPING_YAML_PATH} not found!")
        return None
    
    # Parse YAML manually to handle the special format with indentation and comments
    key_mapping = {}
    replacing_keys = {}
    unused_keys = set()
    keys_to_remove = set()  # All duplicate keys that should be removed
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
            continue
        
        # Check if this is a main key (not indented)
        if not original_line.startswith(' ') and not original_line.startswith('\t'):
            if ': ' in line:
                key, value = line.split(': ', 1)
                key = key.strip()
                value = value.strip()
                
                # Set current main key for processing indented lines
                current_main_key = key
                
                # If we're in an unused section, mark this key as unused
                if is_unused_section:
                    unused_keys.add(key)
                    key_mapping[key] = key
                elif is_replacement_section:
                    replacing_keys[key] = []
                    key_mapping[key] = key  # Map to itself initially
                else:
                    # It's a normal key
                    key_mapping[key] = key  # Map to itself
        
        # Check if this is an indented key (duplicate or replacement)
        elif (original_line.startswith(' ') or original_line.startswith('\t')) and current_main_key:
            if ': ' in line:
                key, value = line.split(': ', 1)
                key = key.strip()
                value = value.strip()
                
                # Always mark indented keys for removal (they are duplicates)
                keys_to_remove.add(key)
                
                if is_replacement_section and key != current_main_key:
                    # This is a replaced key, map it to the current main key
                    key_mapping[key] = current_main_key
                    replacing_keys[current_main_key].append(key)
                elif not is_replacement_section and key == current_main_key:
                    # This is a duplicate of the main key, just mark for removal
                    pass  # Already marked for removal above
    
    print(f"Loaded mapping:")
    print(f"- Total keys: {len(key_mapping)}")
    print(f"- Replacement keys: {len([k for k in replacing_keys.keys() if replacing_keys[k]])}")
    print(f"- Unused keys: {len(unused_keys)}")
    print(f"- Duplicate keys to remove: {len(keys_to_remove)}")
    
    return key_mapping, replacing_keys, unused_keys, keys_to_remove

def update_arb_files(key_mapping, replacing_keys, unused_keys, keys_to_remove, remove_unused=False):
    """Update ARB files based on the key mapping"""
    
    # Load existing ARB data
    with open(ZH_ARB_PATH, 'r', encoding='utf-8') as f:
        zh_data = json.load(f, object_pairs_hook=OrderedDict)
    
    with open(EN_ARB_PATH, 'r', encoding='utf-8') as f:
        en_data = json.load(f, object_pairs_hook=OrderedDict)
    
    original_zh_count = len([k for k in zh_data.keys() if not k.startswith('@')])
    original_en_count = len([k for k in en_data.keys() if not k.startswith('@')])
    
    # Apply replacements
    new_zh_data = OrderedDict()
    new_en_data = OrderedDict()
    
    # Copy metadata first
    for key, value in zh_data.items():
        if key.startswith('@'):
            new_zh_data[key] = value
    
    for key, value in en_data.items():
        if key.startswith('@'):
            new_en_data[key] = value
    
    replaced_count = 0
    removed_unused_count = 0
    removed_duplicate_count = 0
    
    # Process all keys - use the mapping to decide which keys to keep
    processed_target_keys = set()
    
    for original_key in zh_data.keys():
        if original_key.startswith('@'):
            continue
            
        # Skip if this key should be removed as unused
        if remove_unused and original_key in unused_keys:
            removed_unused_count += 1
            print(f"Removing unused key: {original_key}")
            continue
            
        # Skip if this key is a duplicate/indented key from YAML
        if original_key in keys_to_remove:
            removed_duplicate_count += 1
            print(f"Removing duplicate key: {original_key}")
            continue
            
        # Get the target key (might be itself or a replacement)
        target_key = key_mapping.get(original_key, original_key)
        
        if target_key != original_key:
            replaced_count += 1
            print(f"Mapping {original_key} -> {target_key}")
        
        # Only add the target key if we haven't processed it yet
        # This ensures we don't duplicate keys that multiple original keys map to
        if target_key not in processed_target_keys:
            # Use the first occurrence's value (preferably the target key itself if it exists)
            if target_key in zh_data:
                new_zh_data[target_key] = zh_data[target_key]
            elif original_key in zh_data:
                new_zh_data[target_key] = zh_data[original_key]
                
            if target_key in en_data:
                new_en_data[target_key] = en_data[target_key]
            elif original_key in en_data:
                new_en_data[target_key] = en_data[original_key]
                
            processed_target_keys.add(target_key)
    
    # Write updated ARB files
    with open(ZH_ARB_PATH, 'w', encoding='utf-8') as f:
        json.dump(new_zh_data, f, ensure_ascii=False, indent=2)
    
    with open(EN_ARB_PATH, 'w', encoding='utf-8') as f:
        json.dump(new_en_data, f, ensure_ascii=False, indent=2)
    
    new_zh_count = len([k for k in new_zh_data.keys() if not k.startswith('@')])
    new_en_count = len([k for k in new_en_data.keys() if not k.startswith('@')])
    
    print(f"\n=== ARB Files Updated ===")
    print(f"Original key count: {original_zh_count}")
    print(f"New key count: {new_zh_count}")
    print(f"Keys replaced by mapping: {replaced_count}")
    print(f"Duplicate keys removed: {removed_duplicate_count}")
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
                    # Look for various patterns of key usage
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
            
            # Remove references to unused keys if requested
            if remove_unused:
                for unused_key in unused_keys:
                    patterns = [
                        rf'AppLocalizations\.of\(context\)\.{re.escape(unused_key)}\b',
                        rf'l10n\.{re.escape(unused_key)}\b',
                        rf'context\.l10n\.{re.escape(unused_key)}\b'
                    ]
                    
                    for pattern in patterns:
                        matches = re.findall(pattern, content)
                        if matches:
                            print(f"Warning: Found {len(matches)} references to unused key '{unused_key}' in {dart_file}")
                            # For safety, we'll just warn about them
            
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
    print("=== Applying Enhanced Custom YAML Mapping to ARB Files ===")
    
    # Create backups
    backup_arb_files()
    
    # Load mapping
    result = load_yaml_mapping()
    if result is None:
        return
    
    key_mapping, replacing_keys, unused_keys, keys_to_remove = result
    
    if unused_keys:
        if remove_unused:
            print(f"Will remove {len(unused_keys)} unused keys from ARB files")
        else:
            print(f"Found {len(unused_keys)} unused keys (use --remove-unused to remove them)")
    
    if keys_to_remove:
        print(f"Will remove {len(keys_to_remove)} duplicate/indented keys from ARB files")
    
    # Update ARB files
    update_arb_files(key_mapping, replacing_keys, unused_keys, keys_to_remove, remove_unused)
    
    # Update code references
    update_code_references(key_mapping, unused_keys, remove_unused)
    
    print(f"\n=== Success! ===")
    print(f"ARB files and code references have been updated according to the enhanced custom mapping.")
    print(f"Backup created in: {BACKUP_DIR}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Apply ARB key mapping with enhanced duplicate handling")
    parser.add_argument("--remove-unused", action="store_true", 
                       help="Remove unused keys from ARB files")
    parser.add_argument("--mapping", type=str, default=KEY_MAPPING_YAML_PATH,
                       help="Path to the YAML mapping file")
    
    args = parser.parse_args()
    
    if args.mapping != KEY_MAPPING_YAML_PATH:
        KEY_MAPPING_YAML_PATH = args.mapping
    
    apply_yaml_mapping(remove_unused=args.remove_unused)
