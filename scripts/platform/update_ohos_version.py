#!/usr/bin/env python3
"""
更新鸿蒙OS平台版本信息
"""

import json
import sys
import re
from pathlib import Path

# 尝试导入json5，如果不存在则使用正则表达式处理
try:
    import json5
    HAS_JSON5 = True
except ImportError:
    HAS_JSON5 = False

def update_ohos_version(project_root, version_info):
    """更新鸿蒙平台版本信息
    
    Args:
        project_root: 项目根目录
        version_info: 版本信息字典，包含 versionCode 和 versionName
    
    Returns:
        bool: 更新是否成功
    """
    ohos_dir = Path(project_root) / 'ohos'
    
    if not ohos_dir.exists():
        print("警告: 鸿蒙平台目录不存在")
        return False
    
    success = True
    
    # 更新 app.json5
    app_config_file = ohos_dir / 'app' / 'app.json5'
    if app_config_file.exists():
        if not update_json5_version(app_config_file, version_info):
            success = False
    else:
        print(f"警告: {app_config_file} 不存在")
    
    # 更新 config.json
    entry_config_file = ohos_dir / 'entry' / 'src' / 'main' / 'config.json'
    if entry_config_file.exists():
        if not update_json_version(entry_config_file, version_info):
            success = False
    else:
        print(f"警告: {entry_config_file} 不存在")
    
    return success

def update_json5_version(file_path, version_info):
    """更新JSON5格式的版本信息
    
    Args:
        file_path: 文件路径
        version_info: 版本信息
        
    Returns:
        bool: 更新是否成功
    """
    try:
        # 读取JSON5文件
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        if HAS_JSON5:
            # 使用json5库解析和更新
            try:
                data = json5.loads(content)
                data['app']['versionCode'] = version_info['versionCode']
                data['app']['versionName'] = version_info['versionName']
                
                # 写回文件
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(json5.dumps(data, indent=2, ensure_ascii=False))
                    
                print(f"已更新 {file_path}")
                return True
            except Exception as e:
                print(f"json5解析失败，使用正则表达式: {e}")
                # 继续使用正则表达式方法
        
        # 使用正则表达式替换（备用方法）
        # 替换versionCode
        content = re.sub(
            r'"versionCode":\s*\d+',
            f'"versionCode": {version_info["versionCode"]}',
            content
        )
        
        # 替换versionName
        content = re.sub(
            r'"versionName":\s*"[^"]*"',
            f'"versionName": "{version_info["versionName"]}"',
            content
        )
        
        # 写回文件
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
            
        print(f"已更新 {file_path}")
        return True
        
    except Exception as e:
        print(f"更新 {file_path} 失败: {e}")
        return False

def update_json_version(file_path, version_info):
    """更新JSON格式的版本信息
    
    Args:
        file_path: 文件路径
        version_info: 版本信息
        
    Returns:
        bool: 更新是否成功
    """
    try:
        # 读取JSON文件
        with open(file_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
        
        # 更新版本信息
        config['app']['versionCode'] = version_info['versionCode']
        config['app']['versionName'] = version_info['versionName']
        
        # 更新最小兼容版本（如果存在）
        if 'minCompatibleVersionCode' in config['app']:
            config['app']['minCompatibleVersionCode'] = version_info['versionCode']
        
        # 写回文件
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2, ensure_ascii=False)
            
        print(f"已更新 {file_path}")
        return True
        
    except Exception as e:
        print(f"更新 {file_path} 失败: {e}")
        return False

def main():
    """主函数，用于独立运行此脚本"""
    if len(sys.argv) < 4:
        print("用法: python update_ohos_version.py <项目根目录> <版本名称> <版本代码>")
        print("示例: python update_ohos_version.py . 1.0.0 20250620001")
        sys.exit(1)
    
    project_root = sys.argv[1]
    version_name = sys.argv[2]
    version_code = int(sys.argv[3])
    
    version_info = {
        'versionName': version_name,
        'versionCode': version_code
    }
    
    if update_ohos_version(project_root, version_info):
        print("鸿蒙OS版本信息更新成功")
    else:
        print("鸿蒙OS版本信息更新失败")
        sys.exit(1)

if __name__ == '__main__':
    main() 