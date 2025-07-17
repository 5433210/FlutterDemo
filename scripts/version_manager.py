#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
版本管理器 - 简化版本管理操作的菜单式工具
"""

import os
import sys
import subprocess
from pathlib import Path
import yaml

class VersionManager:
    """版本管理器"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.version_config_file = self.project_root / 'version.yaml'
        
    def load_current_version(self):
        """加载当前版本信息"""
        try:
            with open(self.version_config_file, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)
                version = config.get('version', {})
                return {
                    'major': version.get('major', 1),
                    'minor': version.get('minor', 0),
                    'patch': version.get('patch', 0),
                    'build': version.get('build', '20250717001'),
                    'prerelease': version.get('prerelease', '')
                }
        except Exception as e:
            print(f"❌ 读取版本配置失败: {e}")
            return None
    
    def show_current_version(self):
        """显示当前版本信息"""
        version = self.load_current_version()
        if not version:
            return
            
        print("\n" + "="*50)
        print("📋 当前版本信息")
        print("="*50)
        print(f"版本号: {version['major']}.{version['minor']}.{version['patch']}")
        print(f"构建号: {version['build']}")
        if version['prerelease']:
            print(f"预发布: {version['prerelease']}")
        print(f"完整版本: {version['major']}.{version['minor']}.{version['patch']}+{version['build']}")
        if version['prerelease']:
            print(f"预发布版本: {version['major']}.{version['minor']}.{version['patch']}-{version['prerelease']}+{version['build']}")
        print("="*50)
    
    def update_build_number(self):
        """更新构建号"""
        print("\n🔄 正在更新构建号...")
        try:
            result = subprocess.run([
                sys.executable, 
                str(self.project_root / 'scripts' / 'update_build_number.py')
            ], capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode == 0:
                print("✅ 构建号更新成功！")
                print(result.stdout)
            else:
                print("❌ 构建号更新失败！")
                print(result.stderr)
                
        except Exception as e:
            print(f"❌ 执行失败: {e}")
    
    def set_version(self, version_type):
        """设置版本号"""
        current = self.load_current_version()
        if not current:
            return
            
        if version_type == 'patch':
            new_version = f"{current['major']}.{current['minor']}.{current['patch'] + 1}"
            print(f"\n🔧 升级补丁版本: {current['major']}.{current['minor']}.{current['patch']} → {new_version}")
        elif version_type == 'minor':
            new_version = f"{current['major']}.{current['minor'] + 1}.0"
            print(f"\n🔧 升级次版本: {current['major']}.{current['minor']}.{current['patch']} → {new_version}")
        elif version_type == 'major':
            new_version = f"{current['major'] + 1}.0.0"
            print(f"\n🔧 升级主版本: {current['major']}.{current['minor']}.{current['patch']} → {new_version}")
        else:
            return
            
        confirm = input("确认升级版本吗？(y/N): ").strip().lower()
        if confirm != 'y':
            print("❌ 操作已取消")
            return
            
        try:
            result = subprocess.run([
                sys.executable,
                str(self.project_root / 'scripts' / 'generate_version_info.py'),
                '--set-version', new_version
            ], capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode == 0:
                print("✅ 版本更新成功！")
                print(result.stdout)
            else:
                print("❌ 版本更新失败！")
                print(result.stderr)
                
        except Exception as e:
            print(f"❌ 执行失败: {e}")
    
    def set_custom_version(self):
        """设置自定义版本号"""
        current = self.load_current_version()
        if not current:
            return
            
        print(f"\n📝 当前版本: {current['major']}.{current['minor']}.{current['patch']}")
        print("请输入新版本号 (格式: 主版本.次版本.补丁版本，如: 2.0.0)")
        
        while True:
            version_input = input("新版本号: ").strip()
            if not version_input:
                print("❌ 操作已取消")
                return
                
            try:
                parts = version_input.split('.')
                if len(parts) != 3:
                    raise ValueError("版本号格式错误")
                    
                major, minor, patch = map(int, parts)
                if major < 0 or minor < 0 or patch < 0:
                    raise ValueError("版本号不能为负数")
                    
                break
                
            except ValueError as e:
                print(f"❌ 版本号格式错误: {e}")
                print("请输入正确的版本号格式 (如: 1.2.3)")
                continue
        
        print(f"\n🔧 设置版本号: {current['major']}.{current['minor']}.{current['patch']} → {version_input}")
        confirm = input("确认设置版本号吗？(y/N): ").strip().lower()
        if confirm != 'y':
            print("❌ 操作已取消")
            return
            
        try:
            result = subprocess.run([
                sys.executable,
                str(self.project_root / 'scripts' / 'generate_version_info.py'),
                '--set-version', version_input
            ], capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode == 0:
                print("✅ 版本设置成功！")
                print(result.stdout)
            else:
                print("❌ 版本设置失败！")
                print(result.stderr)
                
        except Exception as e:
            print(f"❌ 执行失败: {e}")
    
    def show_build_history(self):
        """显示构建历史"""
        print("\n📚 正在获取构建历史...")
        try:
            result = subprocess.run([
                sys.executable,
                str(self.project_root / 'scripts' / 'update_build_number.py'),
                '--history'
            ], capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode == 0:
                print(result.stdout)
            else:
                print("❌ 获取构建历史失败！")
                print(result.stderr)
                
        except Exception as e:
            print(f"❌ 执行失败: {e}")
    
    def show_menu(self):
        """显示主菜单"""
        while True:
            os.system('cls' if os.name == 'nt' else 'clear')
            
            print("🎯 字字珠玑 - 版本管理器")
            print("="*50)
            
            self.show_current_version()
            
            print("\n📋 操作菜单:")
            print("1. 🔄 更新构建号 (日常开发)")
            print("2. 🔧 升级补丁版本 (bug修复: x.x.X)")
            print("3. 🚀 升级次版本 (新功能: x.X.0)")
            print("4. 🎉 升级主版本 (重大更新: X.0.0)")
            print("5. 📝 设置自定义版本号")
            print("6. 📚 查看构建历史")
            print("0. 🚪 退出")
            
            print("\n" + "="*50)
            choice = input("请选择操作 (0-6): ").strip()
            
            if choice == '0':
                print("\n👋 再见！")
                break
            elif choice == '1':
                self.update_build_number()
                input("\n按回车键继续...")
            elif choice == '2':
                self.set_version('patch')
                input("\n按回车键继续...")
            elif choice == '3':
                self.set_version('minor')
                input("\n按回车键继续...")
            elif choice == '4':
                self.set_version('major')
                input("\n按回车键继续...")
            elif choice == '5':
                self.set_custom_version()
                input("\n按回车键继续...")
            elif choice == '6':
                self.show_build_history()
                input("\n按回车键继续...")
            else:
                print("❌ 无效选择，请重新输入")
                input("\n按回车键继续...")

def main():
    """主函数"""
    try:
        manager = VersionManager()
        manager.show_menu()
    except KeyboardInterrupt:
        print("\n\n👋 用户中断，再见！")
    except Exception as e:
        print(f"\n❌ 程序出错: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
