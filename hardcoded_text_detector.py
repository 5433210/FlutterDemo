#!/usr/bin/env python3
import os
import re
import json
import glob
from collections import defaultdict

# Constants
CODE_DIR = "lib"
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
REPORT_DIR = "hardcoded_text_report"

# Ensure report directory exists
if not os.path.exists(REPORT_DIR):
    os.makedirs(REPORT_DIR)

# Regular expressions to detect Chinese text
CHINESE_PATTERN = r'[\u4e00-\u9fff]+'  # Basic Chinese character range

# Regular expressions for different contexts
PATTERNS = {
    "Text Widget": [
        r'Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'Text\.rich\(.*?text:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'SelectableText\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    "UI Properties": [
        r'hintText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'labelText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'title:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'subtitle:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'tooltip:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'semanticLabel:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    "Dialog/Message": [
        r'message:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'content:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'SnackBar\(.*?content:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    "String Variable": [
        r'String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'final\s+String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'const\s+String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    "Return Value": [
        r'return\s+[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    "Exception/Log": [
        r'throw\s+\w+\([\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'print\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'log\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'logger\.\w+\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
}

# Exclusion patterns (comments, URLs, etc.)
EXCLUSIONS = [
    r'^\s*//.*$',  # Single line comments
    r'/\*.*?\*/',  # Multi-line comments
    r'https?://\S+',  # URLs
]

def load_arb_values():
    """Load all Chinese values from the ARB file"""
    with open(ZH_ARB_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    values = set()
    for key, value in data.items():
        if not key.startswith('@') and isinstance(value, str):
            values.add(value)
    
    return values

def is_excluded(line, match_start, match_end):
    """Check if the match is in an excluded pattern like a comment"""
    for pattern in EXCLUSIONS:
        for match in re.finditer(pattern, line):
            if match.start() <= match_start and match.end() >= match_end:
                return True
    return False

def find_hardcoded_text():
    """Find all hardcoded Chinese text in the code"""
    hardcoded_text = defaultdict(list)
    
    # Load ARB values for comparison
    arb_values = load_arb_values()
    
    for dart_file in glob.glob(os.path.join(CODE_DIR, "**/*.dart"), recursive=True):
        with open(dart_file, 'r', encoding='utf-8') as f:
            try:
                content = f.read()
                lines = content.split('\n')
                
                for line_num, line in enumerate(lines, 1):
                    for context, patterns in PATTERNS.items():
                        for pattern in patterns:
                            for match in re.finditer(pattern, line):
                                chinese_text = match.group(1)
                                
                                # Skip if no Chinese characters
                                if not re.search(CHINESE_PATTERN, chinese_text):
                                    continue
                                
                                # Skip if in an excluded section
                                if is_excluded(line, match.start(1), match.end(1)):
                                    continue
                                    
                                # Skip if the text is already in ARB
                                if chinese_text in arb_values:
                                    continue
                                
                                # Add to the results
                                file_path = os.path.relpath(dart_file, os.path.dirname(CODE_DIR))
                                hardcoded_text[context].append({
                                    'file': file_path,
                                    'line': line_num,
                                    'text': chinese_text,
                                    'snippet': line.strip(),
                                })
            except UnicodeDecodeError:
                print(f"Error reading file: {dart_file}")
    
    return hardcoded_text

def suggest_arb_key(text, context):
    """Suggest an ARB key for the hardcoded text"""
    # Clean the text for use in a key
    # Remove non-alphanumeric characters and limit length
    key_base = re.sub(r'[^\w\s]', '', text)
    key_base = re.sub(r'\s+', '_', key_base).lower()
    key_base = key_base[:20]  # Limit length
    
    # Add context prefix based on the type
    if context == "Text Widget":
        prefix = "text"
    elif context == "UI Properties":
        prefix = "ui"
    elif context == "Dialog/Message":
        prefix = "msg"
    elif context == "String Variable":
        prefix = "str"
    elif context == "Return Value":
        prefix = "val"
    elif context == "Exception/Log":
        prefix = "log"
    else:
        prefix = "common"
    
    return f"{prefix}_{key_base}"

def generate_reports(hardcoded_text):
    """Generate reports of hardcoded text"""
    # Summary report
    with open(os.path.join(REPORT_DIR, "summary.txt"), 'w', encoding='utf-8') as f:
        f.write("=== Hardcoded Chinese Text Summary ===\n\n")
        
        total = sum(len(items) for items in hardcoded_text.values())
        f.write(f"Total instances: {total}\n\n")
        
        for context, items in hardcoded_text.items():
            f.write(f"{context}: {len(items)} instances\n")
    
    # Detailed report
    with open(os.path.join(REPORT_DIR, "detailed.txt"), 'w', encoding='utf-8') as f:
        f.write("=== Hardcoded Chinese Text Detailed Report ===\n\n")
        
        for context, items in hardcoded_text.items():
            f.write(f"== {context} ==\n\n")
            
            for item in items:
                f.write(f"File: {item['file']}\n")
                f.write(f"Line: {item['line']}\n")
                f.write(f"Text: \"{item['text']}\"\n")
                f.write(f"Snippet: {item['snippet']}\n")
                f.write(f"Suggested key: {suggest_arb_key(item['text'], context)}\n")
                f.write("\n---\n\n")
    
    # ARB entries file
    with open(os.path.join(REPORT_DIR, "suggested_arb_entries.json"), 'w', encoding='utf-8') as f:
        entries = {}
        
        for context, items in hardcoded_text.items():
            for item in items:
                key = suggest_arb_key(item['text'], context)
                # Avoid key collision
                i = 1
                original_key = key
                while key in entries:
                    key = f"{original_key}_{i}"
                    i += 1
                entries[key] = item['text']
        
        json.dump(entries, f, ensure_ascii=False, indent=2)
    
    print(f"Generated reports in {REPORT_DIR}")

def main():
    print("=== Hardcoded Chinese Text Detector ===")
    
    # Find hardcoded text
    hardcoded_text = find_hardcoded_text()
    
    # Generate reports
    generate_reports(hardcoded_text)
    
    # Summary
    total = sum(len(items) for items in hardcoded_text.values())
    print(f"Found {total} instances of hardcoded Chinese text")
    
    for context, items in hardcoded_text.items():
        print(f"  - {context}: {len(items)}")
    
    print(f"\nReports available in: {REPORT_DIR}")
    print("  - summary.txt: Overview of findings")
    print("  - detailed.txt: Detailed report with file locations")
    print("  - suggested_arb_entries.json: Suggested ARB entries")

if __name__ == "__main__":
    main()
