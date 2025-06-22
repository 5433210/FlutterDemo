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
REPORT_DIR = "arb_report"

# Ensure backup directory exists
if not os.path.exists(BACKUP_DIR):
    os.makedirs(BACKUP_DIR)

# Ensure report directory exists
if not os.path.exists(REPORT_DIR):
    os.makedirs(REPORT_DIR)

print(f"Created backup directory: {BACKUP_DIR}")
print(f"Created report directory: {REPORT_DIR}")

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
        r'AppLocalizations\.of\(context\)\.([a-zA-Z0-9_]+)',
        r'AppLocalizations\(.*?\)\.([a-zA-Z0-9_]+)'
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
            if not any(set(k[1]) == set(keys) for k in identical_values):
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
        most_used_key = max(keys, key=lambda k: len(key_usage.get(k, [])) if k in key_usage else 0)
        for key in keys:
            if key != most_used_key:
                keys_to_merge.append((key, most_used_key))
    
    # Similar keys that might be merged
    similar_keys_to_review = []
    for value1, value2, keys1, keys2 in similar_values:
        for k1 in keys1:
            for k2 in keys2:
                if k1 != k2:  # Don't compare a key with itself
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

# Step 7: Generate reports
def generate_reports(zh_data, en_data, key_usage, optimizations):
    """Generate detailed reports for review"""
    
    # Report 1: Unused keys
    with open(os.path.join(REPORT_DIR, "unused_keys.txt"), 'w', encoding='utf-8') as f:
        f.write("=== Unused ARB Keys ===\n")
        f.write(f"Total: {len(optimizations['unused_keys'])} keys\n\n")
        
        for key in sorted(optimizations['unused_keys']):
            zh_value = zh_data.get(key, "")
            en_value = en_data.get(key, "")
            f.write(f"Key: {key}\n")
            f.write(f"  ZH: {zh_value}\n")
            f.write(f"  EN: {en_value}\n\n")
    
    # Report 2: Keys to merge
    with open(os.path.join(REPORT_DIR, "keys_to_merge.txt"), 'w', encoding='utf-8') as f:
        f.write("=== Keys to Merge (Identical Values) ===\n")
        f.write(f"Total: {len(optimizations['keys_to_merge'])} keys\n\n")
        
        merged_sets = {}
        for old_key, new_key in optimizations['keys_to_merge']:
            if new_key in merged_sets:
                merged_sets[new_key].append(old_key)
            else:
                merged_sets[new_key] = [old_key]
        
        for new_key, old_keys in merged_sets.items():
            zh_value = zh_data.get(new_key, "")
            en_value = en_data.get(new_key, "")
            f.write(f"Keep: {new_key}\n")
            f.write(f"  ZH: {zh_value}\n")
            f.write(f"  EN: {en_value}\n")
            f.write(f"Merge from:\n")
            for old_key in old_keys:
                f.write(f"  - {old_key}\n")
            f.write(f"Usage count: {len(key_usage.get(new_key, []))}\n\n")
    
    # Report 3: Similar keys to review
    with open(os.path.join(REPORT_DIR, "similar_keys.txt"), 'w', encoding='utf-8') as f:
        f.write("=== Similar Keys to Review ===\n")
        f.write(f"Total: {len(optimizations['similar_keys_to_review'])} pairs\n\n")
        
        # Group by key pairs to avoid duplicates
        reviewed_pairs = set()
        for k1, k2, v1, v2 in optimizations['similar_keys_to_review']:
            if (k1, k2) not in reviewed_pairs and (k2, k1) not in reviewed_pairs:
                reviewed_pairs.add((k1, k2))
                
                f.write(f"Key 1: {k1}\n")
                f.write(f"  ZH: {v1}\n")
                f.write(f"  EN: {en_data.get(k1, '')}\n")
                f.write(f"  Usage count: {len(key_usage.get(k1, []))}\n\n")
                
                f.write(f"Key 2: {k2}\n")
                f.write(f"  ZH: {v2}\n")
                f.write(f"  EN: {en_data.get(k2, '')}\n")
                f.write(f"  Usage count: {len(key_usage.get(k2, []))}\n\n")
                
                f.write("---\n\n")
    
    # Report 4: Keys usage statistics
    with open(os.path.join(REPORT_DIR, "key_usage.txt"), 'w', encoding='utf-8') as f:
        f.write("=== Key Usage Statistics ===\n")
        f.write(f"Total keys in ARB: {sum(1 for k in zh_data.keys() if not k.startswith('@'))}\n")
        f.write(f"Total keys used in code: {len(key_usage)}\n")
        f.write(f"Unused keys: {len(optimizations['unused_keys'])}\n\n")
        
        f.write("Top used keys:\n")
        for key, files in sorted(key_usage.items(), key=lambda x: len(x[1]), reverse=True)[:20]:
            f.write(f"{key}: used in {len(files)} files\n")
    
    # Create mapping file for reference
    mapping = {}
    for old_key, new_key in optimizations['keys_to_merge']:
        mapping[old_key] = new_key
    
    for old_key, new_key in optimizations['keys_to_rename']:
        mapping[old_key] = new_key
    
    with open(os.path.join(REPORT_DIR, "key_mapping.json"), 'w', encoding='utf-8') as f:
        json.dump(mapping, f, ensure_ascii=False, indent=2)
    
    print(f"Generated reports in {REPORT_DIR}")

# Step 8: Interactive review and apply optimizations
def interactive_review(zh_data, en_data, optimizations, key_usage):
    """Interactive review of optimization suggestions"""
    print("\n=== Interactive Review ===")
    
    # Create a copy of the data for modification
    new_zh_data = OrderedDict(zh_data)
    new_en_data = OrderedDict(en_data)
    
    # Final mapping of old keys to new keys
    key_mapping = {}
    
    # Step 1: Review unused keys
    print(f"\n1. Unused keys ({len(optimizations['unused_keys'])})")
    print("These keys are not found in any code files and can be removed.")
    print("Options: [y] Yes, remove all  [n] No, keep all  [r] Review one by one")
    choice = input("Your choice [y/n/r]: ").lower()
    
    if choice == 'y':
        # Remove all unused keys
        for key in optimizations['unused_keys']:
            if key in new_zh_data:
                del new_zh_data[key]
            if f"@{key}" in new_zh_data:
                del new_zh_data[f"@{key}"]
            if key in new_en_data:
                del new_en_data[key]
            if f"@{key}" in new_en_data:
                del new_en_data[f"@{key}"]
        print(f"Removed {len(optimizations['unused_keys'])} unused keys")
    elif choice == 'r':
        # Review each unused key
        keys_to_remove = []
        for key in optimizations['unused_keys']:
            zh_value = zh_data.get(key, "")
            en_value = en_data.get(key, "")
            print(f"\nKey: {key}")
            print(f"  ZH: {zh_value}")
            print(f"  EN: {en_value}")
            remove = input("Remove this key? [y/n]: ").lower() == 'y'
            if remove:
                keys_to_remove.append(key)
        
        # Remove selected keys
        for key in keys_to_remove:
            if key in new_zh_data:
                del new_zh_data[key]
            if f"@{key}" in new_zh_data:
                del new_zh_data[f"@{key}"]
            if key in new_en_data:
                del new_en_data[key]
            if f"@{key}" in new_en_data:
                del new_en_data[f"@{key}"]
        print(f"Removed {len(keys_to_remove)} unused keys")
    else:
        print("Keeping all unused keys")
    
    # Step 2: Review keys to merge
    print(f"\n2. Keys to merge ({len(optimizations['keys_to_merge'])})")
    print("These keys have identical values and can be merged.")
    print("Options: [y] Yes, merge all  [n] No, don't merge any  [r] Review one by one")
    choice = input("Your choice [y/n/r]: ").lower()
    
    if choice == 'y':
        # Merge all keys
        for old_key, new_key in optimizations['keys_to_merge']:
            key_mapping[old_key] = new_key
        print(f"Merged {len(optimizations['keys_to_merge'])} keys")
    elif choice == 'r':
        # Review each merge
        for old_key, new_key in optimizations['keys_to_merge']:
            zh_value_old = zh_data.get(old_key, "")
            zh_value_new = zh_data.get(new_key, "")
            print(f"\nMerge: {old_key} -> {new_key}")
            print(f"  Old key: {old_key}")
            print(f"    ZH: {zh_value_old}")
            print(f"    Usage: {len(key_usage.get(old_key, []))} files")
            print(f"  New key: {new_key}")
            print(f"    ZH: {zh_value_new}")
            print(f"    Usage: {len(key_usage.get(new_key, []))} files")
            merge = input("Merge these keys? [y/n]: ").lower() == 'y'
            if merge:
                key_mapping[old_key] = new_key
    else:
        print("Not merging any keys")
    
    # Step 3: Review similar keys
    print(f"\n3. Similar keys to review ({len(set((k1, k2) for k1, k2, _, _ in optimizations['similar_keys_to_review']))})")
    print("These keys have similar values and might be candidates for merging.")
    print("Options: [y] Review and merge  [n] Skip this step")
    choice = input("Your choice [y/n]: ").lower()
    
    if choice == 'y':
        # Review similar keys
        reviewed_pairs = set()
        for k1, k2, v1, v2 in optimizations['similar_keys_to_review']:
            if (k1, k2) not in reviewed_pairs and (k2, k1) not in reviewed_pairs:
                reviewed_pairs.add((k1, k2))
                
                print(f"\nSimilar keys:")
                print(f"  Key 1: {k1}")
                print(f"    ZH: {v1}")
                print(f"    EN: {en_data.get(k1, '')}")
                print(f"    Usage: {len(key_usage.get(k1, []))} files")
                print(f"  Key 2: {k2}")
                print(f"    ZH: {v2}")
                print(f"    EN: {en_data.get(k2, '')}")
                print(f"    Usage: {len(key_usage.get(k2, []))} files")
                
                print("\nOptions: [1] Merge to Key 1  [2] Merge to Key 2  [s] Skip")
                merge_choice = input("Your choice [1/2/s]: ").lower()
                
                if merge_choice == '1':
                    key_mapping[k2] = k1
                elif merge_choice == '2':
                    key_mapping[k1] = k2
    else:
        print("Skipping similar keys review")
    
    # Step 4: Apply key mapping and create final ARB files
    # Create new dictionaries with all proper keys
    final_zh_data = OrderedDict()
    final_en_data = OrderedDict()
    
    # First, add locale info
    final_zh_data["@@locale"] = new_zh_data.get("@@locale", "zh")
    final_en_data["@@locale"] = new_en_data.get("@@locale", "en")
    
    # Handle regular keys (non-metadata)
    for key, value in new_zh_data.items():
        if key.startswith('@') or key == "@@locale":
            continue
        
        # If this key is mapped to another key, skip it
        if key in key_mapping:
            continue
        
        # Otherwise, include it in the final data
        final_zh_data[key] = value
        
        # Include the English translation if available
        if key in new_en_data:
            final_en_data[key] = new_en_data[key]
    
    # Handle metadata
    for key, value in new_zh_data.items():
        if key.startswith('@') and key != "@@locale":
            # Extract the base key
            base_key = key[1:]
            # If base key is not mapped, include the metadata
            if base_key not in key_mapping and base_key in final_zh_data:
                final_zh_data[key] = value
    
    for key, value in new_en_data.items():
        if key.startswith('@') and key != "@@locale":
            base_key = key[1:]
            if base_key not in key_mapping and base_key in final_en_data:
                final_en_data[key] = value
    
    return final_zh_data, final_en_data, key_mapping

# Step 9: Save new ARB files
def save_arb_files(new_zh_data, new_en_data):
    """Save new ARB files"""
    with open(ZH_ARB_PATH, 'w', encoding='utf-8') as f:
        json.dump(new_zh_data, f, ensure_ascii=False, indent=2)
    
    with open(EN_ARB_PATH, 'w', encoding='utf-8') as f:
        json.dump(new_en_data, f, ensure_ascii=False, indent=2)
    
    print(f"Saved optimized ARB files")
    print(f"  - {ZH_ARB_PATH}: {len([k for k in new_zh_data if not k.startswith('@') and k != '@@locale'])} keys")
    print(f"  - {EN_ARB_PATH}: {len([k for k in new_en_data if not k.startswith('@') and k != '@@locale'])} keys")

# Step 10: Update code references
def update_code_references(key_mapping):
    """Update code references to use new keys"""
    file_count = 0
    ref_count = 0
    
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
                    ref_count += new_content.count(old_pattern)
                    new_content = new_content.replace(old_pattern, new_pattern)
                    updated = True
        
        if updated:
            file_count += 1
            with open(dart_file, 'w', encoding='utf-8') as f:
                f.write(new_content)
    
    return file_count, ref_count

# Step 11: Generate a clean ARB with sorted keys
def generate_clean_arb(zh_data, en_data):
    """Generate a clean ARB with sorted keys"""
    # Create new dictionaries with sorted keys
    clean_zh_data = OrderedDict()
    clean_en_data = OrderedDict()
    
    # First, add locale info
    clean_zh_data["@@locale"] = zh_data.get("@@locale", "zh")
    clean_en_data["@@locale"] = en_data.get("@@locale", "en")
    
    # Get all regular keys
    regular_keys = [k for k in zh_data.keys() if not k.startswith('@') and k != "@@locale"]
    regular_keys.sort()
    
    # Add regular keys
    for key in regular_keys:
        clean_zh_data[key] = zh_data[key]
        if key in en_data:
            clean_en_data[key] = en_data[key]
    
    # Add metadata
    for key in regular_keys:
        meta_key = f"@{key}"
        if meta_key in zh_data:
            clean_zh_data[meta_key] = zh_data[meta_key]
        if meta_key in en_data:
            clean_en_data[meta_key] = en_data[meta_key]
    
    return clean_zh_data, clean_en_data

# Main function
def main():
    print("=== ARB Optimization Tool ===")
    
    # Step 1: Back up ARB files
    backup_arb_files()
    
    # Step 2: Load ARB files
    zh_data, en_data = load_arb_files()
    print(f"Loaded ARB files: {len(zh_data)} entries in zh, {len(en_data)} entries in en")
    
    # Step 3: Find key usage in code
    key_usage = find_key_usage()
    used_keys = len(key_usage)
    total_keys = sum(1 for k in zh_data.keys() if not k.startswith('@'))
    print(f"Found {used_keys}/{total_keys} keys used in code ({used_keys/total_keys*100:.1f}%)")
    
    # Step 4: Find similar keys
    identical_values, similar_values = find_similar_keys(zh_data, en_data)
    print(f"Found {len(identical_values)} sets of identical values")
    print(f"Found {len(similar_values)} sets of similar values")
    
    # Step 5: Analyze key structure
    key_structure = analyze_key_structure(zh_data)
    top_prefixes = list(key_structure['prefixes'].items())[:5]
    print(f"Top module prefixes: {', '.join([f'{k}({v})' for k, v in top_prefixes])}")
    
    # Step 6: Create optimization suggestions
    optimizations = create_optimization_suggestions(zh_data, en_data, key_usage, identical_values, similar_values, key_structure)
    print(f"Optimization suggestions:")
    print(f"  - {len(optimizations['unused_keys'])} keys to remove")
    print(f"  - {len(optimizations['keys_to_merge'])} keys to merge")
    print(f"  - {len(set((k1, k2) for k1, k2, _, _ in optimizations['similar_keys_to_review']))} similar key pairs to review")
    
    # Step 7: Generate reports for review
    generate_reports(zh_data, en_data, key_usage, optimizations)
    
    # Step 8: Interactive review
    print("\nPlease review the reports in the arb_report directory before continuing.")
    input("Press Enter to continue with interactive review...")
    
    new_zh_data, new_en_data, key_mapping = interactive_review(zh_data, en_data, optimizations, key_usage)
    
    # Step 9: Clean and sort ARB files
    clean_zh_data, clean_en_data = generate_clean_arb(new_zh_data, new_en_data)
    
    # Step 10: Save new ARB files
    save_arb_files(clean_zh_data, clean_en_data)
    
    # Step 11: Update code references
    file_count, ref_count = update_code_references(key_mapping)
    print(f"Updated {ref_count} references in {file_count} files")
    
    # Summary
    initial_keys = sum(1 for k in zh_data.keys() if not k.startswith('@') and k != "@@locale")
    final_keys = sum(1 for k in clean_zh_data.keys() if not k.startswith('@') and k != "@@locale")
    
    print("\n=== Optimization Summary ===")
    print(f"Initial keys: {initial_keys}")
    print(f"Final keys: {final_keys}")
    print(f"Keys reduced: {initial_keys - final_keys} ({(initial_keys - final_keys) / initial_keys * 100:.1f}%)")
    print(f"Keys mapped: {len(key_mapping)}")
    print(f"Files updated: {file_count}")
    print(f"References updated: {ref_count}")
    print(f"ARB files backed up to: {BACKUP_DIR}")
    print(f"Reports available in: {REPORT_DIR}")
    print("\nOptimization complete!")

if __name__ == "__main__":
    main()
