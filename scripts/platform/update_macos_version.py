#!/usr/bin/env python3
"""
更新macOS平台版本信息
"""

import sys
import plistlib
from pathlib import Path

def update_macos_version(project_root, bundle_short_version, bundle_version):
    """更新macOS平台版本信息
    
    Args:
        project_root: 项目根目录
        bundle_short_version: CFBundleShortVersionString (如: 1.0.0)
        bundle_version: CFBundleVersion (构建号)
    
    Returns:
        bool: 更新是否成功
    """
    macos_dir = Path(project_root) / 'macos'
    
    if not macos_dir.exists():
        print("警告: macOS平台目录不存在")
        return False
    
    # 更新 Info.plist
    info_plist_file = macos_dir / 'Runner' / 'Info.plist'
    
    if info_plist_file.exists():
        return update_info_plist(info_plist_file, bundle_short_version, bundle_version)
    else:
        print(f"警告: macOS Info.plist文件不存在: {info_plist_file}")
        return False

def update_info_plist(file_path, bundle_short_version, bundle_version):
    """更新Info.plist文件
    
    Args:
        file_path: 文件路径
        bundle_short_version: CFBundleShortVersionString
        bundle_version: CFBundleVersion
        
    Returns:
        bool: 更新是否成功
    """
    try:
        # 读取plist文件
        with open(file_path, 'rb') as f:
            plist_data = plistlib.load(f)
        
        # 更新版本信息
        plist_data['CFBundleShortVersionString'] = bundle_short_version
        plist_data['CFBundleVersion'] = bundle_version
        
        # 写回文件
        with open(file_path, 'wb') as f:
            plistlib.dump(plist_data, f)
            
        print(f"已更新 {file_path}")
        return True
        
    except Exception as e:
        print(f"更新 {file_path} 失败: {e}")
        return False

def main():
    """主函数，用于独立运行此脚本"""
    if len(sys.argv) < 4:
        print("用法: python update_macos_version.py <项目根目录> <版本名称> <构建号>")
        print("示例: python update_macos_version.py . 1.0.0 20250620001")
        sys.exit(1)
    
    project_root = sys.argv[1]
    bundle_short_version = sys.argv[2]
    bundle_version = sys.argv[3]
    
    if update_macos_version(project_root, bundle_short_version, bundle_version):
        print("macOS版本信息更新成功")
    else:
        print("macOS版本信息更新失败")
        sys.exit(1)

if __name__ == '__main__':
    main() 