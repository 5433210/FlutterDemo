#!/usr/bin/env python3
"""
更新Windows平台版本信息
"""

import sys
import re
from pathlib import Path

def update_windows_version(project_root, file_version, product_version, msix_version=None):
    """更新Windows平台版本信息
    
    Args:
        project_root: 项目根目录
        file_version: 文件版本 (如: 1.0.0.20250620001)
        product_version: 产品版本 (如: 1.0.0.20250620001)  
        msix_version: MSIX版本 (如: 1.0.0.0，符合UWP要求)
    
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

    # 更新 pubspec.yaml 中的 MSIX 配置
    pubspec_file = Path(project_root) / 'pubspec.yaml'
    if pubspec_file.exists():
        # 如果传入了特定的MSIX版本，使用它；否则按照UWP规则生成
        if msix_version:
            final_msix_version = msix_version
        else:
            # Windows 10/11 UWP 软件包要求：第四部分必须保留为 0
            # 版本号格式：主版本.次版本.修订版本.0（第四部分保留给应用商店使用）
            version_parts = file_version.split('.')
            if len(version_parts) >= 3:
                # 确保前三部分都在0-65535范围内
                major = min(int(version_parts[0]), 65535)
                minor = min(int(version_parts[1]), 65535)
                patch = min(int(version_parts[2]), 65535)
                # UWP 要求：第四部分必须为 0
                final_msix_version = f"{major}.{minor}.{patch}.0"
            else:
                final_msix_version = f"{file_version}.0"

        if not update_pubspec_msix(pubspec_file, final_msix_version):
            success = False

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

def update_pubspec_msix(pubspec_path, msix_version):
    """更新pubspec.yaml中的MSIX版本

    Args:
        pubspec_path: pubspec.yaml文件路径
        msix_version: MSIX版本号

    Returns:
        bool: 更新是否成功
    """
    try:
        with open(pubspec_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 更新msix_version
        content = re.sub(
            r'msix_version:\s*[\d.]+',
            f'msix_version: {msix_version}',
            content
        )

        with open(pubspec_path, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"已更新 {pubspec_path} 中的 MSIX 版本: {msix_version}")
        return True

    except Exception as e:
        print(f"更新 {pubspec_path} 失败: {e}")
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
        print("用法: python update_windows_version.py <项目根目录> <文件版本> <产品版本> [MSIX版本]")
        print("示例: python update_windows_version.py . 1.0.0.20250620001 1.0.0.20250620001")
        print("示例: python update_windows_version.py . 1.0.0.20250620001 1.0.0.20250620001 1.0.0.0")
        sys.exit(1)
    
    project_root = sys.argv[1]
    file_version = sys.argv[2]
    product_version = sys.argv[3]
    msix_version = sys.argv[4] if len(sys.argv) > 4 else None
    
    if update_windows_version(project_root, file_version, product_version, msix_version):
        print("Windows版本信息更新成功")
    else:
        print("Windows版本信息更新失败")
        sys.exit(1)

if __name__ == '__main__':
    main() 