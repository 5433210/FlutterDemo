#!/usr/bin/env python3
import json
import os
import re
import glob
from collections import defaultdict, OrderedDict
import datetime
import shutil

# Constants
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
BACKUP_DIR = f"arb_backup_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"
CODE_DIR = "lib"

# Ensure backup directory exists
if not os.path.exists(BACKUP_DIR):
    os.makedirs(BACKUP_DIR)

print(f"Created backup directory: {BACKUP_DIR}")

# Step 1: Back up ARB files
def backup_arb_files():
    """Create backups of ARB files"""
    for arb_file in [ZH_ARB_PATH, EN_ARB_PATH]:
        if os.path.exists(arb_file):
            backup_path = os.path.join(BACKUP_DIR, os.path.basename(arb_file))
            shutil.copy2(arb_file, backup_path)
            print(f"Backed up {arb_file} to {backup_path}")
        else:
            print(f"Warning: ARB file {arb_file} not found!")

# Step 2: Load ARB files
def load_arb_files():
    """Load ARB files and return their data"""
    zh_data, en_data = {}, {}
    
    with open(ZH_ARB_PATH, 'r', encoding='utf-8') as f:
        zh_data = json.load(f, object_pairs_hook=OrderedDict)
    
    with open(EN_ARB_PATH, 'r', encoding='utf-8') as f:
        en_data = json.load(f, object_pairs_hook=OrderedDict)
    
    return zh_data, en_data

# Step 3: Find key usage in code
def find_key_usage():
    """Find all ARB key usages in code"""
    key_usage = defaultdict(list)
    
    # Match patterns like l10n.keyName or AppLocalizations.of(context).keyName
    patterns = [
        r'l10n\.([a-zA-Z0-9_]+)',
        r'AppLocalizations\.of\(context\)\.([a-zA-Z0-9_]+)'
    ]
    
    for dart_file in glob.glob(os.path.join(CODE_DIR, "**/*.dart"), recursive=True):
        with open(dart_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
            for pattern in patterns:
                matches = re.finditer(pattern, content)
                for match in matches:
                    key = match.group(1)
                    key_usage[key].append(dart_file)
    
    return key_usage

# Step 4: Find similar keys based on values
def find_similar_keys(zh_data, en_data):
    """Find similar keys based on their values"""
    # Group keys by their values
    zh_value_to_keys = defaultdict(list)
    en_value_to_keys = defaultdict(list)
    
    for key, value in zh_data.items():
        if isinstance(value, str) and not key.startswith('@'):
            zh_value_to_keys[value].append(key)
    
    for key, value in en_data.items():
        if isinstance(value, str) and not key.startswith('@'):
            en_value_to_keys[value].append(key)
    
    # Find keys with identical values
    identical_values = []
    for value, keys in zh_value_to_keys.items():
        if len(keys) > 1:
            identical_values.append((value, keys))
    
    for value, keys in en_value_to_keys.items():
        if len(keys) > 1:
            # Check if not already in the list
            if not any(k[1] == keys for k in identical_values):
                identical_values.append((value, keys))
    
    # Find keys with very similar values (simple approach)
    similar_values = []
    zh_values = list(zh_value_to_keys.keys())
    
    for i, value1 in enumerate(zh_values):
        for value2 in zh_values[i+1:]:
            # Simple similarity: one is contained in the other or differ by punctuation
            if (value1 in value2 or value2 in value1) or \
               (re.sub(r'[^\w\s]', '', value1) == re.sub(r'[^\w\s]', '', value2)):
                keys1 = zh_value_to_keys[value1]
                keys2 = zh_value_to_keys[value2]
                similar_values.append((value1, value2, keys1, keys2))
    
    return identical_values, similar_values

# Step 5: Analyze keys by module/feature
def analyze_key_structure(zh_data):
    """Analyze key structure to identify module/feature keys"""
    # Identify module prefixes
    prefixes = defaultdict(int)
    for key in zh_data.keys():
        if key.startswith('@'):
            continue
        
        # Extract potential module prefix
        parts = key.split('_')
        if len(parts) > 1:
            prefixes[parts[0]] += 1
        
    # Find common words in keys
    word_frequency = defaultdict(int)
    for key in zh_data.keys():
        if key.startswith('@'):
            continue
            
        words = re.findall(r'[A-Z][a-z]+', key)
        for word in words:
            word_frequency[word.lower()] += 1
    
    return {
        'prefixes': dict(sorted(prefixes.items(), key=lambda x: x[1], reverse=True)),
        'common_words': dict(sorted(word_frequency.items(), key=lambda x: x[1], reverse=True))
    }

# Step 6: Create optimization suggestions
def create_optimization_suggestions(zh_data, en_data, key_usage, identical_values, similar_values, key_structure):
    """Create optimization suggestions"""
    # Keys to remove (not used in code)
    unused_keys = []
    for key in zh_data.keys():
        if not key.startswith('@') and key not in key_usage:
            unused_keys.append(key)
    
    # Keys to merge (identical or very similar values)
    keys_to_merge = []
    for value, keys in identical_values:
        # Keep the most used key
        most_used_key = max(keys, key=lambda k: len(key_usage.get(k, [])))
        for key in keys:
            if key != most_used_key:
                keys_to_merge.append((key, most_used_key))
    
    # Similar keys that might be merged
    similar_keys_to_review = []
    for value1, value2, keys1, keys2 in similar_values:
        for k1 in keys1:
            for k2 in keys2:
                similar_keys_to_review.append((k1, k2, value1, value2))
    
    # Keys that can be renamed for consistency
    keys_to_rename = []
    common_prefixes = [prefix for prefix, count in key_structure['prefixes'].items() if count >= 5]
    
    for key in zh_data.keys():
        if key.startswith('@'):
            continue
            
        # Check if key should have a module prefix but doesn't
        parts = key.split('_')
        if len(parts) == 1:  # No underscore
            words = re.findall(r'[A-Z][a-z]+|[a-z]+', key)
            if len(words) >= 2 and words[0].lower() not in common_prefixes:
                # Suggest adding a module prefix
                for prefix in common_prefixes:
                    if any(word.lower() == prefix for word in words[1:]):
                        keys_to_rename.append((key, f"{prefix}_{key}"))
                        break
    
    return {
        'unused_keys': unused_keys,
        'keys_to_merge': keys_to_merge,
        'similar_keys_to_review': similar_keys_to_review,
        'keys_to_rename': keys_to_rename
    }

# Step 7: Apply optimizations to create new ARB files
def apply_optimizations(zh_data, en_data, optimizations):
    """Apply optimizations to create new ARB files"""
    # Create new dictionaries for optimized data
    new_zh_data = OrderedDict()
    new_en_data = OrderedDict()
    
    # Add locale information
    new_zh_data["@@locale"] = "zh"
    new_en_data["@@locale"] = "en"
    
    # Create key mapping (old key -> new key)
    key_mapping = {}
    
    # Process keys to merge
    for old_key, new_key in optimizations['keys_to_merge']:
        key_mapping[old_key] = new_key
    
    # Process keys to rename
    for old_key, new_key in optimizations['keys_to_rename']:
        key_mapping[old_key] = new_key
    
    # Process keys to keep
    for key in zh_data.keys():
        if key.startswith('@'):
            # Skip metadata for now
            continue
            
        if key in optimizations['unused_keys']:
            # Skip unused keys
            continue
            
        if key in key_mapping:
            # This key is mapped to another key
            continue
            
        # Keep this key
        new_key = key_mapping.get(key, key)
        new_zh_data[new_key] = zh_data[key]
        
        if key in en_data:
            new_en_data[new_key] = en_data[key]
        else:
            # Key exists in zh but not in en
            print(f"Warning: Key '{key}' exists in zh ARB but not in en ARB")
    
    # Add metadata
    for key in zh_data.keys():
        if key.startswith('@'):
            base_key = key[1:]
            if base_key in key_mapping:
                new_key = f"@{key_mapping[base_key]}"
                new_zh_data[new_key] = zh_data[key]
            elif base_key not in optimizations['unused_keys']:
                new_zh_data[key] = zh_data[key]
    
    for key in en_data.keys():
        if key.startswith('@'):
            base_key = key[1:]
            if base_key in key_mapping:
                new_key = f"@{key_mapping[base_key]}"
                new_en_data[new_key] = en_data[key]
            elif base_key not in optimizations['unused_keys']:
                new_en_data[key] = en_data[key]
    
    return new_zh_data, new_en_data, key_mapping

# Step 8: Update code references
def update_code_references(key_mapping):
    """Update code references to use new keys"""
    count = 0
    for dart_file in glob.glob(os.path.join(CODE_DIR, "**/*.dart"), recursive=True):
        updated = False
        with open(dart_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = content
        
        # Replace patterns: l10n.oldKey -> l10n.newKey
        for old_key, new_key in key_mapping.items():
            patterns = [
                (f'l10n.{old_key}', f'l10n.{new_key}'),
                (f'AppLocalizations.of(context).{old_key}', f'AppLocalizations.of(context).{new_key}')
            ]
            
            for old_pattern, new_pattern in patterns:
                if old_pattern in new_content:
                    new_content = new_content.replace(old_pattern, new_pattern)
                    updated = True
        
        if updated:
            count += 1
            with open(dart_file, 'w', encoding='utf-8') as f:
                f.write(new_content)
    
    return count

# Step 9: Save new ARB files
def save_arb_files(new_zh_data, new_en_data):
    """Save new ARB files"""
    with open(ZH_ARB_PATH, 'w', encoding='utf-8') as f:
        json.dump(new_zh_data, f, ensure_ascii=False, indent=2)
    
    with open(EN_ARB_PATH, 'w', encoding='utf-8') as f:
        json.dump(new_en_data, f, ensure_ascii=False, indent=2)

# Main function
def main():
    print("Starting ARB file optimization...")
    
    # Step 1: Back up ARB files
    backup_arb_files()
    
    # Step 2: Load ARB files
    zh_data, en_data = load_arb_files()
    print(f"Loaded ARB files: {len(zh_data)} keys in zh, {len(en_data)} keys in en")
    
    # Step 3: Find key usage in code
    key_usage = find_key_usage()
    print(f"Found {len(key_usage)} keys used in code")
    
    # Step 4: Find similar keys
    identical_values, similar_values = find_similar_keys(zh_data, en_data)
    print(f"Found {len(identical_values)} sets of identical values")
    print(f"Found {len(similar_values)} sets of similar values")
    
    # Step 5: Analyze key structure
    key_structure = analyze_key_structure(zh_data)
    print(f"Found {len(key_structure['prefixes'])} potential module prefixes")
    
    # Step 6: Create optimization suggestions
    optimizations = create_optimization_suggestions(zh_data, en_data, key_usage, identical_values, similar_values, key_structure)
    print(f"Optimization suggestions:")
    print(f"  - {len(optimizations['unused_keys'])} keys to remove")
    print(f"  - {len(optimizations['keys_to_merge'])} keys to merge")
    print(f"  - {len(optimizations['similar_keys_to_review'])} similar keys to review")
    print(f"  - {len(optimizations['keys_to_rename'])} keys to rename")
    
    # Step 7: Apply optimizations
    new_zh_data, new_en_data, key_mapping = apply_optimizations(zh_data, en_data, optimizations)
    print(f"New ARB files: {len(new_zh_data)} keys in zh, {len(new_en_data)} keys in en")
    print(f"Total keys reduced: {len(zh_data) - len(new_zh_data)} in zh, {len(en_data) - len(new_en_data)} in en")
    
    # Step 8: Update code references
    updated_files = update_code_references(key_mapping)
    print(f"Updated references in {updated_files} files")
    
    # Step 9: Save new ARB files
    save_arb_files(new_zh_data, new_en_data)
    print("Saved new ARB files")
    
    print("\nARB optimization complete!")
    print(f"Original ARB files backed up to {BACKUP_DIR}")
    print(f"Keys removed: {len(optimizations['unused_keys'])}")
    print(f"Keys merged: {len(optimizations['keys_to_merge'])}")
    print(f"Keys renamed: {len(optimizations['keys_to_rename'])}")
    print(f"Files updated: {updated_files}")

if __name__ == "__main__":
    main()
