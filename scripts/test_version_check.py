#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import os

def main():
    print("测试脚本开始运行...")
    print(f"Python版本: {sys.version}")
    print(f"当前工作目录: {os.getcwd()}")
    print(f"脚本参数: {sys.argv}")
    
    # 测试文件存在性
    files_to_check = [
        'version.yaml',
        'pubspec.yaml',
        'android/local.properties'
    ]
    
    for file_path in files_to_check:
        if os.path.exists(file_path):
            print(f"[OK] 文件存在: {file_path}")
        else:
            print(f"[ERROR] 文件不存在: {file_path}")
    
    print("测试脚本结束")
    return 0

if __name__ == '__main__':
    sys.exit(main()) 