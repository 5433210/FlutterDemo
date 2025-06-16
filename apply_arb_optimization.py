#!/usr/bin/env python3
import os
import re
import glob
import json
import subprocess
import time
import sys

# Constants
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
CODE_DIR = "lib"
MAPPING_PATH = "arb_report/key_mapping.json"

def load_key_mapping():
    """Load key mapping from file"""
    if not os.path.exists(MAPPING_PATH):
        print(f"Error: Mapping file {MAPPING_PATH} not found.")
        print("Please run the interactive_arb_optimizer.py script first.")
        sys.exit(1)
        
    with open(MAPPING_PATH, 'r', encoding='utf-8') as f:
        return json.load(f)

def update_code_references(key_mapping):
    """Update code references using the key mapping"""
    file_count = 0
    ref_count = 0
    updated_files = []
    
    for dart_file in glob.glob(os.path.join(CODE_DIR, "**/*.dart"), recursive=True):
        updated = False
        with open(dart_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = content
        file_refs = 0
        
        # Replace patterns
        for old_key, new_key in key_mapping.items():
            patterns = [
                (f'l10n.{old_key}', f'l10n.{new_key}'),
                (f'AppLocalizations.of(context).{old_key}', f'AppLocalizations.of(context).{new_key}'),
                (f'AppLocalizations(.*?).{old_key}', f'AppLocalizations\\1.{new_key}')
            ]
            
            for pattern, replacement in patterns:
                if re.search(pattern, new_content):
                    count = len(re.findall(pattern, new_content))
                    file_refs += count
                    ref_count += count
                    new_content = re.sub(pattern, replacement, new_content)
                    updated = True
        
        if updated:
            file_count += 1
            with open(dart_file, 'w', encoding='utf-8') as f:
                f.write(new_content)
            updated_files.append((dart_file, file_refs))
    
    return file_count, ref_count, updated_files

def regenerate_l10n_files():
    """Regenerate localization files using flutter gen-l10n"""
    print("Regenerating localization files...")
    result = subprocess.run(["flutter", "gen-l10n"], capture_output=True, text=True)
    
    if result.returncode != 0:
        print("Error regenerating localization files:")
        print(result.stderr)
        return False
    
    print("Localization files regenerated successfully.")
    return True

def check_build():
    """Check if the project builds successfully"""
    print("Running flutter analyze...")
    result = subprocess.run(["flutter", "analyze"], capture_output=True, text=True)
    
    if result.returncode != 0:
        print("Flutter analyze found issues:")
        print(result.stderr)
        print(result.stdout)
        return False
    
    print("Flutter analyze passed.")
    
    print("Building debug version...")
    result = subprocess.run(["flutter", "build", "--debug"], capture_output=True, text=True)
    
    if result.returncode != 0:
        print("Build failed:")
        print(result.stderr)
        return False
    
    print("Build successful.")
    return True

def main():
    print("=== ARB Optimization Code Updater ===")
    
    # Step 1: Load key mapping
    print("Loading key mapping...")
    key_mapping = load_key_mapping()
    print(f"Loaded {len(key_mapping)} key mappings")
    
    # Step 2: Update code references
    print("Updating code references...")
    start_time = time.time()
    file_count, ref_count, updated_files = update_code_references(key_mapping)
    elapsed_time = time.time() - start_time
    
    print(f"Updated {ref_count} references in {file_count} files in {elapsed_time:.2f} seconds")
    
    # Print updated files
    if updated_files:
        print("\nUpdated files:")
        for file_path, count in sorted(updated_files, key=lambda x: x[1], reverse=True):
            rel_path = os.path.relpath(file_path, os.path.dirname(CODE_DIR))
            print(f"  - {rel_path}: {count} references")
    
    # Step 3: Regenerate localization files
    regenerate_l10n_files()
    
    # Step 4: Check build
    if check_build():
        print("\n✅ ARB optimization and code update completed successfully!")
    else:
        print("\n❌ ARB optimization completed but there are build issues to resolve.")

if __name__ == "__main__":
    main()
