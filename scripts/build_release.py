#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
字字珠玑 - 多平台 Release 构建工具
支持 Windows、Android、iOS、Web、Linux、macOS 等平台的构建
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path
import yaml
import platform

class MultiPlatformBuilder:
    """多平台构建器"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.version_config_file = self.project_root / 'version.yaml'
        self.current_os = platform.system().lower()
        
        # 平台配置
        self.platforms = {
            'windows': {
                'name': 'Windows',
                'icon': '🪟',
                'supported_types': ['msix', 'exe'],
                'default_type': 'msix',
                'available': self.current_os == 'windows',
                'builder_script': 'build_windows.py'
            },
            'android': {
                'name': 'Android',
                'icon': '🤖',
                'supported_types': ['apk', 'aab'],
                'default_type': 'apk',
                'available': True,  # Android 可以在所有平台构建
                'builder_script': 'build_android.py'
            },
            'ios': {
                'name': 'iOS',
                'icon': '📱',
                'supported_types': ['ipa'],
                'default_type': 'ipa',
                'available': self.current_os == 'darwin',
                'builder_script': 'build_ios.py'
            },
            'web': {
                'name': 'Web',
                'icon': '🌐',
                'supported_types': ['web'],
                'default_type': 'web',
                'available': True,  # Web 可以在所有平台构建
                'builder_script': 'build_web.py'
            },
            'linux': {
                'name': 'Linux',
                'icon': '🐧',
                'supported_types': ['snap', 'deb', 'appimage'],
                'default_type': 'snap',
                'available': self.current_os == 'linux',
                'builder_script': 'build_linux.py'
            },
            'macos': {
                'name': 'macOS',
                'icon': '🍎',
                'supported_types': ['dmg', 'pkg'],
                'default_type': 'dmg',
                'available': self.current_os == 'darwin',
                'builder_script': 'build_macos.py'
            }
        }
    
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
            
        print("\n" + "="*70)
        print("📋 当前版本信息")
        print("="*70)
        print(f"版本号: {version['major']}.{version['minor']}.{version['patch']}")
        print(f"构建号: {version['build']}")
        if version['prerelease']:
            print(f"预发布: {version['prerelease']}")
        print(f"完整版本: {version['major']}.{version['minor']}.{version['patch']}+{version['build']}")
        if version['prerelease']:
            print(f"预发布版本: {version['major']}.{version['minor']}.{version['patch']}-{version['prerelease']}+{version['build']}")
        print("="*70)
    
    def show_platform_status(self):
        """显示平台支持状态"""
        print("\n📱 平台支持状态:")
        print("-" * 70)
        
        for platform_id, config in self.platforms.items():
            status = "✅ 可用" if config['available'] else "❌ 不可用"
            types = ", ".join(config['supported_types'])
            print(f"{config['icon']} {config['name']:<10} {status:<8} 支持类型: {types}")
        
        print("-" * 70)
        print(f"💻 当前系统: {platform.system()} {platform.machine()}")
    
    def get_available_platforms(self):
        """获取可用的平台列表"""
        return {k: v for k, v in self.platforms.items() if v['available']}
    
    def update_version(self, version_type):
        """更新版本号"""
        print(f"\n🔄 更新版本号 ({version_type})...")
        
        try:
            if version_type == 'build':
                print("更新构建号...")
                result = subprocess.run([
                    sys.executable, 
                    str(self.project_root / 'scripts' / 'update_build_number.py')
                ], cwd=self.project_root)
            else:
                current = self.load_current_version()
                if not current:
                    return False
                    
                if version_type == 'patch':
                    new_version = f"{current['major']}.{current['minor']}.{current['patch'] + 1}"
                    print(f"升级补丁版本: {current['major']}.{current['minor']}.{current['patch']} → {new_version}")
                elif version_type == 'minor':
                    new_version = f"{current['major']}.{current['minor'] + 1}.0"
                    print(f"升级次版本: {current['major']}.{current['minor']}.{current['patch']} → {new_version}")
                elif version_type == 'major':
                    new_version = f"{current['major'] + 1}.0.0"
                    print(f"升级主版本: {current['major']}.{current['minor']}.{current['patch']} → {new_version}")
                else:
                    print(f"❌ 未知的版本类型: {version_type}")
                    return False
                
                result = subprocess.run([
                    sys.executable,
                    str(self.project_root / 'scripts' / 'generate_version_info.py'),
                    '--set-version', new_version
                ], cwd=self.project_root)
            
            if result.returncode == 0:
                print("✅ 版本更新成功!")
                return True
            else:
                print("❌ 版本更新失败!")
                return False
                
        except Exception as e:
            print(f"❌ 版本更新失败: {e}")
            return False
    
    def build_platform(self, platform_id, build_type=None, update_version=None):
        """构建指定平台"""
        if platform_id not in self.platforms:
            print(f"❌ 未知的平台: {platform_id}")
            return False
        
        platform_config = self.platforms[platform_id]
        
        if not platform_config['available']:
            print(f"❌ 平台 {platform_config['name']} 在当前系统上不可用")
            return False
        
        # 检查构建脚本是否存在
        builder_script = self.project_root / 'scripts' / platform_config['builder_script']
        if not builder_script.exists():
            print(f"❌ 构建脚本不存在: {builder_script}")
            print(f"💡 提示: 该平台的构建功能尚未实现")
            return False
        
        # 更新版本（如果指定）
        version_updated = False
        if update_version:
            if not self.update_version(update_version):
                return False
            version_updated = True
            self.show_current_version()
        
        # 确定构建类型
        if not build_type:
            build_type = platform_config['default_type']
        elif build_type not in platform_config['supported_types']:
            print(f"❌ 平台 {platform_config['name']} 不支持构建类型: {build_type}")
            print(f"💡 支持的类型: {', '.join(platform_config['supported_types'])}")
            return False
        
        # 调用平台特定的构建脚本
        print(f"\n🚀 开始构建 {platform_config['icon']} {platform_config['name']} ({build_type})...")
        print("="*70)
        
        try:
            cmd = [sys.executable, str(builder_script), '--type', build_type]
            # 🔧 修复：如果已经在这里更新了版本，就不要再传递给子脚本
            # 避免重复更新版本号导致跳号
            # if update_version:
            #     cmd.extend(['--update-version', update_version])
            
            result = subprocess.run(cmd, cwd=self.project_root)
            
            if result.returncode == 0:
                print(f"\n🎉 {platform_config['name']} 构建成功!")
                return True
            else:
                print(f"\n❌ {platform_config['name']} 构建失败!")
                return False
                
        except Exception as e:
            print(f"❌ 构建过程出错: {e}")
            return False
    
    def show_menu(self):
        """显示交互式菜单"""
        while True:
            os.system('cls' if os.name == 'nt' else 'clear')
            
            print("🎯 字字珠玑 - 多平台 Release 构建工具")
            print("="*70)
            
            self.show_current_version()
            self.show_platform_status()
            
            available_platforms = self.get_available_platforms()
            
            print("\n📋 构建选项:")
            menu_index = 1
            platform_menu = {}
            
            for platform_id, config in available_platforms.items():
                print(f"{menu_index}. {config['icon']} 构建 {config['name']} ({config['default_type']})")
                platform_menu[str(menu_index)] = platform_id
                menu_index += 1
            
            print(f"{menu_index}. 🔄 仅更新版本号")
            print("0. 🚪 退出")
            
            print("\n" + "="*70)
            choice = input("请选择操作: ").strip()
            
            if choice == '0':
                print("\n👋 再见！")
                break
            elif choice in platform_menu:
                platform_id = platform_menu[choice]
                platform_config = self.platforms[platform_id]
                
                # 询问是否更新版本
                print(f"\n🚀 准备构建 {platform_config['icon']} {platform_config['name']}")
                print("="*50)

                # 显示当前版本信息
                current_version = self.load_current_version()
                if current_version:
                    print(f"📋 当前版本: {current_version['major']}.{current_version['minor']}.{current_version['patch']}+{current_version['build']}")

                print(f"\n构建前是否更新版本？")
                print("1. 🔄 更新构建号")
                print("2. 🔧 升级补丁版本")
                print("3. 🚀 升级次版本")
                print("4. 🎉 升级主版本")
                print("5. 跳过版本更新，直接构建")
                print("0. 🔙 返回上级菜单")

                version_choice = input("请选择 (0-5): ").strip()

                if version_choice == '0':
                    continue  # 返回上级菜单
                elif version_choice == '5':
                    update_version = None  # 跳过版本更新
                else:
                    version_types = {'1': 'build', '2': 'patch', '3': 'minor', '4': 'major'}
                    update_version = version_types.get(version_choice)

                    if not update_version:
                        print("❌ 无效选择")
                        input("\n按回车键继续...")
                        continue
                
                self.build_platform(platform_id, update_version=update_version)
                input("\n按回车键继续...")
            elif choice == str(menu_index):
                # 仅更新版本号
                print("\n📋 版本更新选项:")
                print("1. 🔄 更新构建号")
                print("2. 🔧 升级补丁版本")
                print("3. 🚀 升级次版本")
                print("4. 🎉 升级主版本")
                print("0. 🔙 返回上级菜单")

                version_choice = input("请选择版本更新类型 (0-4): ").strip()

                if version_choice == '0':
                    continue  # 返回上级菜单

                version_types = {'1': 'build', '2': 'patch', '3': 'minor', '4': 'major'}

                if version_choice in version_types:
                    if self.update_version(version_types[version_choice]):
                        self.show_current_version()
                else:
                    print("❌ 无效选择")
                input("\n按回车键继续...")
            else:
                print("❌ 无效选择，请重新输入")
                input("\n按回车键继续...")

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='字字珠玑多平台 Release 构建工具')
    parser.add_argument('--platform', 
                       choices=['windows', 'android', 'ios', 'web', 'linux', 'macos'],
                       help='目标平台')
    parser.add_argument('--type', help='构建类型')
    parser.add_argument('--update-version', 
                       choices=['build', 'patch', 'minor', 'major'],
                       help='构建前更新版本号')
    parser.add_argument('--interactive', action='store_true',
                       help='启动交互式菜单')
    parser.add_argument('--list-platforms', action='store_true',
                       help='列出支持的平台')
    
    args = parser.parse_args()
    
    try:
        builder = MultiPlatformBuilder()
        
        if args.list_platforms:
            builder.show_current_version()
            builder.show_platform_status()
            return
        
        if args.interactive or len(sys.argv) == 1:
            # 交互式菜单模式
            builder.show_menu()
        else:
            # 命令行模式
            if not args.platform:
                print("❌ 请指定目标平台 (--platform)")
                print("💡 使用 --list-platforms 查看支持的平台")
                sys.exit(1)
            
            builder.show_current_version()
            success = builder.build_platform(args.platform, args.type, args.update_version)
            
            if not success:
                sys.exit(1)
                
    except KeyboardInterrupt:
        print("\n\n👋 用户中断，再见！")
    except Exception as e:
        print(f"\n❌ 程序出错: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
