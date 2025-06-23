#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
简化版Android构建脚本
专门用于解决当前构建问题
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path
from datetime import datetime

def run_command(cmd, cwd=None, shell=False):
    """安全执行命令，处理编码问题"""
    try:
        result = subprocess.run(
            cmd, 
            cwd=cwd, 
            capture_output=True, 
            text=True, 
            shell=shell,
            encoding='utf-8', 
            errors='ignore',
            timeout=300  # 5分钟超时
        )
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        print(f"⚠️ 命令执行超时: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
        return False, "", "Timeout"
    except Exception as e:
        print(f"⚠️ 命令执行异常: {e}")
        return False, "", str(e)

def check_flutter():
    """检查Flutter环境"""
    print("🔍 检查Flutter...")
    
    # 在Windows上尝试不同的方式调用flutter
    flutter_commands = [
        ['flutter', '--version'],
        ['flutter.bat', '--version'],
        ['cmd', '/c', 'flutter', '--version'],
        ['powershell', '-Command', 'flutter --version']
    ]
    
    for cmd in flutter_commands:
        try:
            success, stdout, stderr = run_command(cmd)
            if success and 'Flutter' in stdout:
                lines = stdout.split('\n')
                for line in lines:
                    if 'Flutter' in line:
                        print(f"✅ {line.strip()}")
                        return True
        except Exception as e:
            continue
    
    # 最后尝试直接在shell中执行
    try:
        success, stdout, stderr = run_command('flutter --version', shell=True)
        if success and 'Flutter' in stdout:
            lines = stdout.split('\n')
            for line in lines:
                if 'Flutter' in line:
                    print(f"✅ {line.strip()}")
                    return True
    except Exception as e:
        pass
    
    print("❌ Flutter未找到或无法执行")
    print("请确保Flutter已安装并添加到PATH环境变量中")
    return False

def build_apk_simple(flavor="direct", build_type="debug"):
    """简化的APK构建"""
    print(f"🔨 构建 {flavor} {build_type} APK...")
    
    project_root = Path(__file__).parent.parent
    
    # 构建命令 - 使用shell方式在Windows上更可靠
    if flavor and flavor != "default":
        cmd_str = f"flutter build apk --{build_type} --flavor {flavor}"
    else:
        cmd_str = f"flutter build apk --{build_type}"
    
    print(f"执行命令: {cmd_str}")
    
    # 执行构建 - 使用shell方式
    success, stdout, stderr = run_command(cmd_str, cwd=project_root, shell=True)
    
    if success:
        print("✅ APK构建成功")
        
        # 查找构建产物
        apk_dir = project_root / "build" / "app" / "outputs" / "flutter-apk"
        if apk_dir.exists():
            apk_files = list(apk_dir.glob("*.apk"))
            for apk in apk_files:
                size_mb = apk.stat().st_size / (1024 * 1024)
                print(f"📦 构建产物: {apk.name} ({size_mb:.1f} MB)")
        
        return True
    else:
        print("❌ APK构建失败")
        if stderr:
            print(f"错误信息: {stderr}")
        return False

def organize_apk(flavor="direct", build_type="debug"):
    """整理APK到发布目录"""
    print("📦 整理构建产物...")
    
    project_root = Path(__file__).parent.parent
    source_dir = project_root / "build" / "app" / "outputs" / "flutter-apk"
    target_dir = project_root / "releases" / "android"
    
    # 确保目标目录存在
    target_dir.mkdir(parents=True, exist_ok=True)
    
    # 查找APK文件
    apk_files = list(source_dir.glob("*.apk"))
    
    if not apk_files:
        print("❌ 未找到APK文件")
        return False
    
    # 复制文件
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    for apk_file in apk_files:
        # 生成新文件名
        name_parts = apk_file.stem.split('-')
        if len(name_parts) >= 3:
            new_name = f"demo-{build_type}-{timestamp}.apk"
        else:
            new_name = f"{apk_file.stem}-{timestamp}.apk"
        
        target_file = target_dir / new_name
        
        try:
            import shutil
            shutil.copy2(apk_file, target_file)
            size_mb = target_file.stat().st_size / (1024 * 1024)
            print(f"✅ 已复制: {new_name} ({size_mb:.1f} MB)")
        except Exception as e:
            print(f"❌ 复制失败: {e}")
            return False
    
    return True

def main():
    parser = argparse.ArgumentParser(description="简化版Android构建脚本")
    parser.add_argument("--flavor", default="direct", help="构建渠道 (default: direct)")
    parser.add_argument("--build-type", choices=["debug", "profile", "release"], 
                       default="debug", help="构建类型 (default: debug)")
    parser.add_argument("--check-only", action="store_true", help="仅检查环境")
    
    args = parser.parse_args()
    
    print("=== 简化版Android构建脚本 ===")
    
    # 检查Flutter环境
    if not check_flutter():
        print("❌ Flutter环境检查失败")
        sys.exit(1)
    
    if args.check_only:
        print("✅ 环境检查完成")
        sys.exit(0)
    
    # 构建APK
    if build_apk_simple(args.flavor, args.build_type):
        # 整理产物
        if organize_apk(args.flavor, args.build_type):
            print("\n🎉 构建完成！")
            
            # 显示结果
            releases_dir = Path(__file__).parent.parent / "releases" / "android"
            print(f"📁 APK文件位置: {releases_dir}")
            
            # 列出最新的APK文件
            apk_files = list(releases_dir.glob("*.apk"))
            if apk_files:
                latest_apk = max(apk_files, key=lambda x: x.stat().st_mtime)
                size_mb = latest_apk.stat().st_size / (1024 * 1024)
                print(f"📱 最新APK: {latest_apk.name} ({size_mb:.1f} MB)")
        else:
            print("❌ 产物整理失败")
            sys.exit(1)
    else:
        print("❌ 构建失败")
        sys.exit(1)

if __name__ == "__main__":
    main() 