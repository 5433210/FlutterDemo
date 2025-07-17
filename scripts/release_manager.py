#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
字字珠玑 - 发布管理工具
管理和查看发布文件
"""

import os
import sys
import json
from pathlib import Path
from datetime import datetime

class ReleaseManager:
    """发布管理器"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.releases_dir = self.project_root / 'releases'
    
    def list_releases(self):
        """列出所有发布版本"""
        if not self.releases_dir.exists():
            print("❌ 发布目录不存在")
            return
        
        print("📦 CharAsGem - 发布版本列表")
        print("="*70)
        
        # 获取所有版本目录
        version_dirs = []
        for item in self.releases_dir.iterdir():
            if item.is_dir() and item.name.startswith('v'):
                version_dirs.append(item)
        
        if not version_dirs:
            print("📭 暂无发布版本")
            return
        
        # 按版本号排序
        version_dirs.sort(key=lambda x: x.name, reverse=True)
        
        for version_dir in version_dirs:
            self.show_version_info(version_dir)
    
    def show_version_info(self, version_dir):
        """显示版本信息"""
        version_name = version_dir.name
        print(f"\n🏷️  版本: {version_name}")
        print("-" * 50)
        
        # 检查各平台
        platforms = ['windows', 'android', 'ios', 'web', 'linux', 'macos']
        
        for platform in platforms:
            platform_dir = version_dir / platform
            if platform_dir.exists():
                self.show_platform_files(platform, platform_dir)
    
    def show_platform_files(self, platform, platform_dir):
        """显示平台文件"""
        platform_icons = {
            'windows': '🪟',
            'android': '🤖',
            'ios': '📱',
            'web': '🌐',
            'linux': '🐧',
            'macos': '🍎'
        }
        
        icon = platform_icons.get(platform, '📦')
        print(f"  {icon} {platform.title()}:")
        
        # 获取所有文件
        files = []
        for file_path in platform_dir.iterdir():
            if file_path.is_file() and not file_path.name.endswith('.info.json'):
                files.append(file_path)
        
        if not files:
            print("    📭 暂无文件")
            return
        
        for file_path in sorted(files):
            self.show_file_info(file_path)
    
    def show_file_info(self, file_path):
        """显示文件信息"""
        # 尝试读取对应的 info.json 文件
        info_file = file_path.with_suffix(file_path.suffix + '.info.json')
        
        if info_file.exists():
            try:
                with open(info_file, 'r', encoding='utf-8') as f:
                    info = json.load(f)
                
                build_date = datetime.fromisoformat(info['build_date']).strftime('%Y-%m-%d %H:%M')
                print(f"    📄 {file_path.name}")
                print(f"       📊 大小: {info['file_size']}")
                print(f"       🏗️  类型: {info['build_type']}")
                print(f"       📅 构建: {build_date}")
                
            except Exception as e:
                print(f"    📄 {file_path.name}")
                print(f"       ⚠️ 无法读取信息: {e}")
        else:
            # 直接显示文件信息
            size_mb = file_path.stat().st_size / (1024 * 1024)
            print(f"    📄 {file_path.name}")
            print(f"       📊 大小: {size_mb:.2f} MB")
    
    def clean_old_releases(self, keep_versions=3):
        """清理旧版本（保留最新的几个版本）"""
        if not self.releases_dir.exists():
            print("❌ 发布目录不存在")
            return
        
        print(f"🧹 清理旧版本（保留最新 {keep_versions} 个版本）")
        print("="*50)
        
        # 获取所有版本目录
        version_dirs = []
        for item in self.releases_dir.iterdir():
            if item.is_dir() and item.name.startswith('v'):
                version_dirs.append(item)
        
        if len(version_dirs) <= keep_versions:
            print(f"✅ 当前只有 {len(version_dirs)} 个版本，无需清理")
            return
        
        # 按版本号排序，保留最新的
        version_dirs.sort(key=lambda x: x.name, reverse=True)
        to_remove = version_dirs[keep_versions:]
        
        print(f"📋 将删除以下版本:")
        for version_dir in to_remove:
            print(f"  🗑️  {version_dir.name}")
        
        confirm = input(f"\n确认删除这 {len(to_remove)} 个旧版本吗？(y/N): ").strip().lower()
        
        if confirm == 'y':
            import shutil
            for version_dir in to_remove:
                try:
                    shutil.rmtree(version_dir)
                    print(f"✅ 已删除: {version_dir.name}")
                except Exception as e:
                    print(f"❌ 删除失败 {version_dir.name}: {e}")
        else:
            print("❌ 取消清理操作")
    
    def create_release_summary(self):
        """创建发布摘要文件"""
        if not self.releases_dir.exists():
            print("❌ 发布目录不存在")
            return
        
        print("📋 创建发布摘要...")
        
        summary = {
            "app_name": "CharAsGem",
            "generated_at": datetime.now().isoformat(),
            "releases": []
        }
        
        # 获取所有版本
        version_dirs = []
        for item in self.releases_dir.iterdir():
            if item.is_dir() and item.name.startswith('v'):
                version_dirs.append(item)
        
        version_dirs.sort(key=lambda x: x.name, reverse=True)
        
        for version_dir in version_dirs:
            version_info = {
                "version": version_dir.name,
                "platforms": {}
            }
            
            # 检查各平台
            for platform_dir in version_dir.iterdir():
                if platform_dir.is_dir():
                    platform_name = platform_dir.name
                    platform_files = []
                    
                    for file_path in platform_dir.iterdir():
                        if file_path.is_file() and not file_path.name.endswith('.info.json'):
                            info_file = file_path.with_suffix(file_path.suffix + '.info.json')
                            
                            file_info = {
                                "filename": file_path.name,
                                "size": f"{file_path.stat().st_size / (1024 * 1024):.2f} MB"
                            }
                            
                            if info_file.exists():
                                try:
                                    with open(info_file, 'r', encoding='utf-8') as f:
                                        info_data = json.load(f)
                                    file_info.update(info_data)
                                except:
                                    pass
                            
                            platform_files.append(file_info)
                    
                    if platform_files:
                        version_info["platforms"][platform_name] = platform_files
            
            if version_info["platforms"]:
                summary["releases"].append(version_info)
        
        # 保存摘要文件
        summary_file = self.releases_dir / "release_summary.json"
        with open(summary_file, 'w', encoding='utf-8') as f:
            json.dump(summary, f, ensure_ascii=False, indent=2)
        
        print(f"✅ 发布摘要已保存: {summary_file}")
    
    def show_menu(self):
        """显示交互式菜单"""
        while True:
            os.system('cls' if os.name == 'nt' else 'clear')
            
            print("📦 CharAsGem - 发布管理工具")
            print("="*50)
            print("1. 📋 查看所有发布版本")
            print("2. 🧹 清理旧版本")
            print("3. 📄 创建发布摘要")
            print("4. 📂 打开发布目录")
            print("0. 🚪 退出")
            
            choice = input("\n请选择操作 (0-4): ").strip()
            
            if choice == '0':
                print("\n👋 再见！")
                break
            elif choice == '1':
                self.list_releases()
                input("\n按回车键继续...")
            elif choice == '2':
                keep = input("保留最新几个版本？(默认3): ").strip()
                try:
                    keep_versions = int(keep) if keep else 3
                    self.clean_old_releases(keep_versions)
                except ValueError:
                    print("❌ 请输入有效数字")
                input("\n按回车键继续...")
            elif choice == '3':
                self.create_release_summary()
                input("\n按回车键继续...")
            elif choice == '4':
                if self.releases_dir.exists():
                    os.startfile(str(self.releases_dir))
                    print("📂 已打开发布目录")
                else:
                    print("❌ 发布目录不存在")
                input("\n按回车键继续...")
            else:
                print("❌ 无效选择，请重新输入")
                input("\n按回车键继续...")

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='字字珠玑发布管理工具')
    parser.add_argument('--list', action='store_true', help='列出所有发布版本')
    parser.add_argument('--clean', type=int, metavar='N', help='清理旧版本，保留最新N个')
    parser.add_argument('--summary', action='store_true', help='创建发布摘要')
    parser.add_argument('--interactive', action='store_true', help='启动交互式菜单')
    
    args = parser.parse_args()
    
    manager = ReleaseManager()
    
    if args.list:
        manager.list_releases()
    elif args.clean is not None:
        manager.clean_old_releases(args.clean)
    elif args.summary:
        manager.create_release_summary()
    elif args.interactive or len(sys.argv) == 1:
        manager.show_menu()
    else:
        parser.print_help()

if __name__ == '__main__':
    main()
