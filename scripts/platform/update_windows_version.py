#!/usr/bin/env python3
"""
更新Windows平台版本信息
"""

import sys
import re
from pathlib import Path

def update_windows_version(project_root, file_version, product_version):
    """更新Windows平台版本信息
    
    Args:
        project_root: 项目根目录
        file_version: 文件版本 (如: 1.0.0.20250620001)
        product_version: 产品版本 (如: 1.0.0.20250620001)
    
    Returns:
        bool: 更新是否成功
    """
    windows_dir = Path(project_root) / 'windows'
    
    if not windows_dir.exists():
        print("警告: Windows平台目录不存在")
        return False
    
    success = True
    
    # 更新 Runner.rc
    runner_rc_file = windows_dir / 'runner' / 'Runner.rc'
    if runner_rc_file.exists():
        if not update_runner_rc(runner_rc_file, file_version, product_version):
            success = False
    else:
        print(f"警告: Windows Runner.rc文件不存在: {runner_rc_file}")
        success = False
    
    # 更新 CMakeLists.txt (如果存在版本信息)
    cmake_file = windows_dir / 'CMakeLists.txt'
    if cmake_file.exists():
        if not update_cmake_version(cmake_file, file_version):
            print("警告: 更新Windows CMakeLists.txt失败")
    
    return success

def update_runner_rc(file_path, file_version, product_version):
    """更新Runner.rc文件
    
    Args:
        file_path: 文件路径
        file_version: 文件版本
        product_version: 产品版本
        
    Returns:
        bool: 更新是否成功
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 将版本号转换为逗号分隔格式 (1,0,0,20250620001)
        file_version_comma = file_version.replace('.', ',')
        product_version_comma = product_version.replace('.', ',')
        
        # 更新FILEVERSION
        content = re.sub(
            r'FILEVERSION\s+[\d,]+',
            f'FILEVERSION {file_version_comma}',
            content
        )
        
        # 更新PRODUCTVERSION
        content = re.sub(
            r'PRODUCTVERSION\s+[\d,]+',
            f'PRODUCTVERSION {product_version_comma}',
            content
        )
        
        # 更新VALUE "FileVersion"
        content = re.sub(
            r'VALUE "FileVersion", "[^"]*"',
            f'VALUE "FileVersion", "{file_version}"',
            content
        )
        
        # 更新VALUE "ProductVersion"
        content = re.sub(
            r'VALUE "ProductVersion", "[^"]*"',
            f'VALUE "ProductVersion", "{product_version}"',
            content
        )
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
            
        print(f"已更新 {file_path}")
        return True
        
    except Exception as e:
        print(f"更新 {file_path} 失败: {e}")
        return False

def update_cmake_version(file_path, version):
    """更新CMakeLists.txt中的版本信息
    
    Args:
        file_path: 文件路径
        version: 版本号
        
    Returns:
        bool: 更新是否成功
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 更新VERSION属性（如果存在）
        content = re.sub(
            r'set\(VERSION\s+"[^"]*"\)',
            f'set(VERSION "{version}")',
            content,
            flags=re.IGNORECASE
        )
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
            
        print(f"已更新 {file_path}")
        return True
        
    except Exception as e:
        print(f"更新 {file_path} 失败: {e}")
        return False

def main():
    """主函数，用于独立运行此脚本"""
    if len(sys.argv) < 4:
        print("用法: python update_windows_version.py <项目根目录> <文件版本> <产品版本>")
        print("示例: python update_windows_version.py . 1.0.0.20250620001 1.0.0.20250620001")
        sys.exit(1)
    
    project_root = sys.argv[1]
    file_version = sys.argv[2]
    product_version = sys.argv[3]
    
    if update_windows_version(project_root, file_version, product_version):
        print("Windows版本信息更新成功")
    else:
        print("Windows版本信息更新失败")
        sys.exit(1)

if __name__ == '__main__':
    main() 