#!/usr/bin/env python3
"""
更新Android平台版本信息
"""

import sys
import re
from pathlib import Path

def update_android_version(project_root, version_name, version_code):
    """更新Android平台版本信息
    
    Args:
        project_root: 项目根目录
        version_name: 版本名称 (如: 1.0.0)
        version_code: 版本代码 (构建号)
    
    Returns:
        bool: 更新是否成功
    """
    android_dir = Path(project_root) / 'android'
    
    if not android_dir.exists():
        print("警告: Android平台目录不存在")
        return False
    
    # 更新 build.gradle.kts
    build_gradle_file = android_dir / 'app' / 'build.gradle.kts'
    
    if build_gradle_file.exists():
        return update_build_gradle_kts(build_gradle_file, version_name, version_code)
    else:
        # 尝试 build.gradle (Groovy格式)
        build_gradle_file = android_dir / 'app' / 'build.gradle'
        if build_gradle_file.exists():
            return update_build_gradle(build_gradle_file, version_name, version_code)
        else:
            print(f"警告: Android构建文件不存在")
            return False

def update_build_gradle_kts(file_path, version_name, version_code):
    """更新Kotlin DSL格式的build.gradle.kts文件
    
    Args:
        file_path: 文件路径
        version_name: 版本名称
        version_code: 版本代码
        
    Returns:
        bool: 更新是否成功
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 更新versionCode
        content = re.sub(
            r'versionCode\s*=\s*\d+',
            f'versionCode = {version_code}',
            content
        )
        
        # 更新versionName
        content = re.sub(
            r'versionName\s*=\s*"[^"]*"',
            f'versionName = "{version_name}"',
            content
        )
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
            
        print(f"已更新 {file_path}")
        return True
        
    except Exception as e:
        print(f"更新 {file_path} 失败: {e}")
        return False

def update_build_gradle(file_path, version_name, version_code):
    """更新Groovy格式的build.gradle文件
    
    Args:
        file_path: 文件路径
        version_name: 版本名称
        version_code: 版本代码
        
    Returns:
        bool: 更新是否成功
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 更新versionCode
        content = re.sub(
            r'versionCode\s+\d+',
            f'versionCode {version_code}',
            content
        )
        
        # 更新versionName
        content = re.sub(
            r'versionName\s+"[^"]*"',
            f'versionName "{version_name}"',
            content
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
        print("用法: python update_android_version.py <项目根目录> <版本名称> <版本代码>")
        print("示例: python update_android_version.py . 1.0.0 20250620001")
        sys.exit(1)
    
    project_root = sys.argv[1]
    version_name = sys.argv[2]
    version_code = int(sys.argv[3])
    
    if update_android_version(project_root, version_name, version_code):
        print("Android版本信息更新成功")
    else:
        print("Android版本信息更新失败")
        sys.exit(1)

if __name__ == '__main__':
    main() 