#!/usr/bin/env python3
"""
Apply the key mapping from the edited YAML file to update ARB files and code references.
This script reads the YAML mapping file, updates key_mapping.json, and applies the changes.
"""

import json
import yaml
import os
import re
import shutil
import datetime
import glob
from collections import defaultdict, OrderedDict

# File paths
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
KEY_MAPPING_PATH = os.path.join("arb_report", "key_mapping.json")
YAML_MAPPING_PATH = os.path.join("arb_report", "key_mapping.yaml")
CODE_DIR = "lib"
BACKUP_DIR = f"arb_backup_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"

def load_yaml_file(file_path):
    """Load a YAML file and return its contents."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Error loading {file_path}: {e}")
        return {}

def load_json_file(file_path):
    """Load a JSON file and return its contents as a dictionary."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f, object_pairs_hook=OrderedDict)
    except Exception as e:
        print(f"Error loading {file_path}: {e}")
        return {}

def save_json_file(data, file_path):
    """Save data as a JSON file."""
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"JSON saved to {file_path}")
    except Exception as e:
        print(f"Error saving JSON to {file_path}: {e}")

def create_backup():
    """Create backup of ARB files."""
    os.makedirs(BACKUP_DIR, exist_ok=True)
    
    for arb_file in [ZH_ARB_PATH, EN_ARB_PATH]:
        if os.path.exists(arb_file):
            backup_path = os.path.join(BACKUP_DIR, os.path.basename(arb_file))
            shutil.copy2(arb_file, backup_path)
            print(f"Backed up {arb_file} to {backup_path}")

def parse_yaml_mapping():
    """Parse the YAML mapping file to extract key mapping information."""
    yaml_data = load_yaml_file(YAML_MAPPING_PATH)
    if not yaml_data:
        print("Error: YAML mapping file is empty or could not be loaded.")
        return None
    
    # Initialize the key mapping dictionary
    key_mapping = {}
    
    # Process each entry in the YAML file
    for key, value in yaml_data.items():
        # Skip section headers (comments)
        if isinstance(key, str) and key.startswith("#"):
            continue
        
        # Skip None values (section markers)
        if value is None:
            continue
        
        # Process normal key entries
        if isinstance(key, str) and isinstance(value, str):
            # Check if this is an old key (indented with spaces)
            if key.startswith(" "):
                # This is an old key that is being replaced
                old_key = key.strip()
                
                # Extract the new key from the comment
                match = re.search(r'#\s*Replaced by\s+(\w+)', value)
                if match:
                    new_key = match.group(1)
                    key_mapping[old_key] = new_key
            else:
                # This is either a key that replaces others or a key that doesn't change
                # For keys that don't change, map to themselves
                if "#" not in value:
                    key_mapping[key] = key
                else:
                    # For keys that replace others, extract the replaced keys from the comment
                    match = re.search(r'#\s*Replaces:\s+([\w, ]+)', value)
                    if match:
                        replaced_keys = [k.strip() for k in match.group(1).split(',')]
                        for old_key in replaced_keys:
                            key_mapping[old_key] = key
                    
                    # Also map the key to itself
                    key_mapping[key] = key
    
    return key_mapping

def extract_arb_values_from_yaml():
    """Extract ARB values from the YAML mapping file."""
    yaml_data = load_yaml_file(YAML_MAPPING_PATH)
    if not yaml_data:
        return {}, {}
    
    zh_values = {}
    en_values = {}
    
    # Load existing ARB files to get values not in the YAML
    existing_zh = load_json_file(ZH_ARB_PATH)
    existing_en = load_json_file(EN_ARB_PATH)
    
    # Process each entry in the YAML file
    for key, value in yaml_data.items():
        # Skip section headers and None values
        if isinstance(key, str) and key.startswith("#") or value is None:
            continue
        
        # Process normal key entries
        if isinstance(key, str) and isinstance(value, str):
            # Remove indentation and comments
            clean_key = key.strip()
            clean_value = value.split('#')[0].strip() if '#' in value else value.strip()
            
            # Only store values for keys that aren't being replaced
            if not key.startswith(" "):
                zh_values[clean_key] = clean_value
                
                # Try to find English value from existing ARB
                if clean_key in existing_en:
                    en_values[clean_key] = existing_en[clean_key]
                else:
                    # Fallback to Chinese value
                    en_values[clean_key] = clean_value
    
    return zh_values, en_values

def update_arb_files(zh_values, en_values):
    """Update ARB files with new values."""
    # Load existing ARB files to preserve metadata
    zh_data = load_json_file(ZH_ARB_PATH)
    en_data = load_json_file(EN_ARB_PATH)
    
    # Create new ARB data with preserved metadata
    new_zh_data = OrderedDict()
    new_en_data = OrderedDict()
    
    # Copy metadata (keys starting with @)
    for key, value in zh_data.items():
        if key.startswith('@'):
            if key[1:] in zh_values or key == '@locale':
                new_zh_data[key] = value
    
    for key, value in en_data.items():
        if key.startswith('@'):
            if key[1:] in en_values or key == '@locale':
                new_en_data[key] = value
    
    # Add the locale
    new_zh_data['@@locale'] = 'zh'
    new_en_data['@@locale'] = 'en'
    
    # Add all the values
    for key, value in sorted(zh_values.items()):
        new_zh_data[key] = value
    
    for key, value in sorted(en_values.items()):
        new_en_data[key] = value
    
    # Save the updated ARB files
    save_json_file(new_zh_data, ZH_ARB_PATH)
    save_json_file(new_en_data, EN_ARB_PATH)
    
    print(f"Updated ARB files with {len(zh_values)} keys")

def update_code_references(key_mapping):
    """Update code references to use new key names."""
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

def run_flutter_gen_l10n():
    """Run flutter gen-l10n to regenerate localization files."""
    print("Running flutter gen-l10n to regenerate localization files...")
    
    try:
        import subprocess
        result = subprocess.run(["flutter", "gen-l10n"], 
                               capture_output=True, 
                               text=True,
                               check=False)
        
        if result.returncode == 0:
            print("Successfully regenerated localization files.")
            return True
        else:
            print(f"Error regenerating localization files: {result.stderr}")
            return False
    except Exception as e:
        print(f"Exception while running flutter gen-l10n: {str(e)}")
        print("Please run 'flutter gen-l10n' manually to regenerate localization files.")
        return False

def main():
    """Main function to apply the YAML mapping."""
    print("Applying YAML mapping to ARB files and code references...")
    
    # Create backup
    create_backup()
    
    # Parse the YAML mapping file
    key_mapping = parse_yaml_mapping()
    if not key_mapping:
        print("Failed to parse YAML mapping.")
        return
    
    # Save the updated key mapping
    save_json_file(key_mapping, KEY_MAPPING_PATH)
    
    # Extract ARB values from YAML
    zh_values, en_values = extract_arb_values_from_yaml()
    
    # Update ARB files
    update_arb_files(zh_values, en_values)
    
    # Update code references
    update_code_references(key_mapping)
    
    # Regenerate localization files
    run_flutter_gen_l10n()
    
    print("\nYAML mapping applied successfully!")
    print(f"Backup created in {BACKUP_DIR}")
    print(f"Updated key_mapping.json with {len(key_mapping)} mappings")
    print(f"Updated ARB files with {len(zh_values)} keys")
    print("Run 'flutter analyze' to check for any issues")

if __name__ == "__main__":
    main()
