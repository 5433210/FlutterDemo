#!/usr/bin/env python3
"""
简化版英文硬编码检测器 - 用于测试
"""

import os
import re
import glob

def test_simple_detection():
    """简单检测测试"""    # 简单的英文检测模式
    patterns = [
        r"(?:const\s+)?Text\(\s*'([A-Z][A-Za-z\s]+)'\s*[,)]",
        r'(?:const\s+)?Text\(\s*"([A-Z][A-Za-z\s]+)"\s*[,)]',
        r"tooltip:\s*'([A-Z][A-Za-z\s]+)'",
        r'tooltip:\s*"([A-Z][A-Za-z\s]+)"',
        r"hintText:\s*'([A-Z][A-Za-z\s]+)'",
        r'hintText:\s*"([A-Z][A-Za-z\s]+)"',
        r"labelText:\s*'([A-Z][A-Za-z\s]+)'",
        r'labelText:\s*"([A-Z][A-Za-z\s]+)"',
    ]
    
    results = []
    
    # 测试特定文件
    test_file = "lib/presentation/pages/home_page.dart"
    if os.path.exists(test_file):
        print(f"检测文件: {test_file}")
        try:
            with open(test_file, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
                
            for line_num, line in enumerate(lines, 1):
                print(f"Line {line_num}: {line.strip()}")
                for pattern in patterns:
                    try:
                        matches = re.finditer(pattern, line)
                        for match in matches:
                            text = match.group(1)
                            print(f"  匹配: '{text}' (模式: {pattern})")
                            results.append({
                                'file': test_file,
                                'line': line_num,
                                'text': text,
                                'line_content': line.strip()
                            })
                    except Exception as e:
                        print(f"  正则错误: {e}")
                        
        except Exception as e:
            print(f"文件读取错误: {e}")
    
    print(f"\n检测结果: {len(results)} 个英文硬编码")
    for result in results:
        print(f"  - 文件: {result['file']}, 行: {result['line']}")
        print(f"    文本: '{result['text']}'")
        print(f"    完整行: {result['line_content']}")

if __name__ == "__main__":
    test_simple_detection()
