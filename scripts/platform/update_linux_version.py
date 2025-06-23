#!/usr/bin/env python3
"""
更新Linux平台版本信息
"""

import sys
import re
from pathlib import Path

def update_linux_version(project_root, major, minor, patch, build_number):
    """更新Linux平台版本信息
    
    Args:
        project_root: 项目根目录
        major: 主版本号
        minor: 次版本号
        patch: 修订版本号
        build_number: 构建号
    
    Returns:
        bool: 更新是否成功
    """
    linux_dir = Path(project_root) / 'linux'
    
    if not linux_dir.exists():
        print("警告: Linux平台目录不存在")
        return False
    
    success = True
    
    # 更新 CMakeLists.txt
    cmake_file = linux_dir / 'CMakeLists.txt'
    if cmake_file.exists():
        if not update_cmake_version(cmake_file, major, minor, patch, build_number):
            success = False
    else:
        print(f"警告: Linux CMakeLists.txt文件不存在: {cmake_file}")
        success = False
    
    # 更新其他可能的版本文件
    # 如果有desktop文件、spec文件等也可以在这里更新
    
    return success

def update_cmake_version(file_path, major, minor, patch, build_number):
    """更新CMakeLists.txt文件
    
    Args:
        file_path: 文件路径
        major: 主版本号
        minor: 次版本号
        patch: 修订版本号
        build_number: 构建号
        
    Returns:
        bool: 更新是否成功
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        version_string = f"{major}.{minor}.{patch}-{build_number}"
        
        # 更新各种版本定义
        replacements = [
            (r'set\(APP_VERSION_MAJOR\s+\d+\)', f'set(APP_VERSION_MAJOR {major})'),
            (r'set\(APP_VERSION_MINOR\s+\d+\)', f'set(APP_VERSION_MINOR {minor})'),
            (r'set\(APP_VERSION_PATCH\s+\d+\)', f'set(APP_VERSION_PATCH {patch})'),
            (r'set\(APP_BUILD_NUMBER\s+\w+\)', f'set(APP_BUILD_NUMBER {build_number})'),
            (r'set\(APP_VERSION_STRING\s+"[^"]*"\)', f'set(APP_VERSION_STRING "{version_string}")'),
            (r'set\(VERSION\s+"[^"]*"\)', f'set(VERSION "{version_string}")'),
        ]
        
        for pattern, replacement in replacements:
            content = re.sub(pattern, replacement, content, flags=re.IGNORECASE)
        
        # 如果没有找到版本定义，添加它们
        if 'APP_VERSION_MAJOR' not in content:
            # 在project()声明后添加版本定义
            project_match = re.search(r'project\([^)]+\)', content, re.IGNORECASE)
            if project_match:
                insert_pos = project_match.end()
                version_definitions = f"""

# 应用版本信息
set(APP_VERSION_MAJOR {major})
set(APP_VERSION_MINOR {minor})
set(APP_VERSION_PATCH {patch})
set(APP_BUILD_NUMBER {build_number})
set(APP_VERSION_STRING "{version_string}")
"""
                content = content[:insert_pos] + version_definitions + content[insert_pos:]
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
            
        print(f"已更新 {file_path}")
        return True
        
    except Exception as e:
        print(f"更新 {file_path} 失败: {e}")
        return False

def main():
    """主函数，用于独立运行此脚本"""
    if len(sys.argv) < 6:
        print("用法: python update_linux_version.py <项目根目录> <主版本号> <次版本号> <修订版本号> <构建号>")
        print("示例: python update_linux_version.py . 1 0 0 20250620001")
        sys.exit(1)
    
    project_root = sys.argv[1]
    major = int(sys.argv[2])
    minor = int(sys.argv[3])
    patch = int(sys.argv[4])
    build_number = sys.argv[5]
    
    if update_linux_version(project_root, major, minor, patch, build_number):
        print("Linux版本信息更新成功")
    else:
        print("Linux版本信息更新失败")
        sys.exit(1)

if __name__ == '__main__':
    main() 