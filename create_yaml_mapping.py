#!/usr/bin/env python3
"""
Convert ARB key mapping to a more readable YAML format that shows values and replacement relationships.
This script creates a YAML file that users can edit and then use for further processing.
"""

import json
import yaml
import os
import re
from collections import defaultdict, OrderedDict

# File paths
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
KEY_MAPPING_PATH = os.path.join("arb_report", "key_mapping.json")
YAML_MAPPING_PATH = os.path.join("arb_report", "key_mapping.yaml")

def load_json_file(file_path):
    """Load a JSON file and return its contents as a dictionary."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f, object_pairs_hook=OrderedDict)
    except Exception as e:
        print(f"Error loading {file_path}: {e}")
        return {}

def save_yaml_file(data, file_path):
    """Save data as a YAML file."""
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
        print(f"YAML mapping saved to {file_path}")
    except Exception as e:
        print(f"Error saving YAML to {file_path}: {e}")

def create_yaml_mapping():
    """Create a YAML mapping file from the key_mapping.json and ARB files."""
    # Load the key mapping and ARB files
    key_mapping = load_json_file(KEY_MAPPING_PATH)
    zh_data = load_json_file(ZH_ARB_PATH)
    en_data = load_json_file(EN_ARB_PATH)
    
    if not key_mapping:
        print("Error: Key mapping file is empty or could not be loaded.")
        return False
    
    # Identify keys that replace other keys
    replacing_keys = defaultdict(list)
    for old_key, new_key in key_mapping.items():
        if old_key != new_key:
            replacing_keys[new_key].append(old_key)
    
    # Create a new structured YAML-friendly dictionary
    yaml_data = OrderedDict()
    
    # First section: keys that replace other keys
    yaml_data["# Keys that replace other keys"] = None
    for new_key, old_keys in replacing_keys.items():
        # Get the value from the ARB file (prefer Chinese)
        value = zh_data.get(new_key, en_data.get(new_key, ""))
        
        # Create a comment showing which keys this replaces
        replaced_keys_str = ", ".join(old_keys)
        yaml_data[new_key] = f"{value}  # Replaces: {replaced_keys_str}"
        
        # Add the old keys with their values for reference
        for old_key in old_keys:
            old_value = zh_data.get(old_key, en_data.get(old_key, ""))
            yaml_data[f"  {old_key}"] = f"{old_value}  # Replaced by {new_key}"
    
    # Second section: keys that don't replace others
    yaml_data["# Keys that don't replace others"] = None
    for key in key_mapping:
        if key == key_mapping[key] and key not in replacing_keys:
            value = zh_data.get(key, en_data.get(key, ""))
            yaml_data[key] = value
    
    # Save the YAML file
    save_yaml_file(yaml_data, YAML_MAPPING_PATH)
    
    # Create a README file explaining how to use the YAML mapping
    readme_content = """# Key Mapping YAML File

This YAML file shows all ARB keys with their values after optimization.

## Format

The file is organized into two sections:

1. **Keys that replace other keys** - These are keys that are replacing one or more other keys.
   - The main key is shown with its value and a comment indicating which keys it replaces
   - The old keys are indented and show their original values

2. **Keys that don't replace others** - These are keys that remain unchanged

## How to Edit

You can edit this file to:

1. Change which keys should replace others
2. Modify the replacement relationships
3. Keep more keys if needed
4. Change key values

## Using Your Changes

After editing this file, run the following command to apply your changes:

```
python apply_yaml_mapping.py
```

This will:
1. Read your edited YAML file
2. Update the key_mapping.json file
3. Apply the changes to the ARB files
4. Update code references in your Dart files
"""
    
    with open(os.path.join("arb_report", "key_mapping_README.md"), 'w', encoding='utf-8') as f:
        f.write(readme_content)
    
    return True

def main():
    """Main function to create the YAML mapping."""
    print("Creating YAML mapping from key_mapping.json...")
    
    # Create the arb_report directory if it doesn't exist
    os.makedirs("arb_report", exist_ok=True)
    
    if create_yaml_mapping():
        print("YAML mapping created successfully!")
        print(f"You can now edit {YAML_MAPPING_PATH} to adjust the key mappings.")
    else:
        print("Failed to create YAML mapping.")

if __name__ == "__main__":
    main()
