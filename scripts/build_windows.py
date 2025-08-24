#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
字字珠玑 - Windows 平台构建脚本
支持 MSIX 安装包和便携版可执行文件的构建
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path
import yaml
import shutil

class WindowsBuilder:
    """Windows 平台构建器"""
    
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
            
        print("\n" + "="*60)
        print("📋 当前版本信息")
        print("="*60)
        print(f"版本号: {version['major']}.{version['minor']}.{version['patch']}")
        print(f"构建号: {version['build']}")
        if version['prerelease']:
            print(f"预发布: {version['prerelease']}")
        print(f"完整版本: {version['major']}.{version['minor']}.{version['patch']}+{version['build']}")
        if version['prerelease']:
            print(f"预发布版本: {version['major']}.{version['minor']}.{version['patch']}-{version['prerelease']}+{version['build']}")
        
        # 显示UWP版本号说明
        major = min(version['major'], 65535)
        minor = min(version['minor'], 65535)
        patch = min(version['patch'], 65535)
        msix_version = f"{major}.{minor}.{patch}.0"
        
        print(f"\n🪟 Windows MSIX 版本号:")
        print(f"MSIX版本: {msix_version}")
        print("注意: UWP软件包要求第四部分保留为0（应用商店专用）")
        print("注意: 各部分范围为0-65535")
        print("="*60)
    
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
    
    def run_command(self, command, description):
        """运行命令并显示进度"""
        print(f"🔄 {description}...")
        try:
            # 使用 UTF-8 编码处理命令输出
            process = subprocess.Popen(
                command,
                cwd=self.project_root,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True,
                encoding='utf-8',
                errors='replace'  # 替换无法解码的字符
            )

            # 获取命令输出
            stdout, stderr = process.communicate()

            if process.returncode == 0:
                print(f"✅ {description}完成")
                return True
            else:
                print(f"❌ {description}失败!")
                if stderr:
                    print(f"错误信息: {stderr}")
                return False
        except Exception as e:
            print(f"❌ {description}失败: {e}")
            return False
    
    def get_file_info(self, file_path):
        """获取文件信息"""
        if file_path.exists():
            size_mb = file_path.stat().st_size / (1024 * 1024)
            return {
                'path': str(file_path.absolute()),
                'size': f"{size_mb:.2f} MB"
            }
        return None

    def generate_release_filename(self, build_type, version_info):
        """生成发布文件名"""
        # 格式: CharAsGem_v1.0.3+20250717010_x64.msix
        version_str = f"v{version_info['major']}.{version_info['minor']}.{version_info['patch']}+{version_info['build']}"

        if build_type == 'msix':
            return f"CharAsGem_{version_str}_x64.msix"
        elif build_type == 'portable':
            return f"CharAsGem_{version_str}_x64.exe"
        else:
            return f"CharAsGem_{version_str}_x64.{build_type}"

    def create_release_structure(self, version_info):
        """创建发布目录结构"""
        version_str = f"v{version_info['major']}.{version_info['minor']}.{version_info['patch']}"

        # 创建发布目录结构
        releases_dir = self.project_root / "releases"
        version_dir = releases_dir / version_str
        windows_dir = version_dir / "windows"

        # 创建目录
        windows_dir.mkdir(parents=True, exist_ok=True)

        return {
            'releases_dir': releases_dir,
            'version_dir': version_dir,
            'windows_dir': windows_dir
        }

    def copy_to_releases(self, source_path, build_type, version_info):
        """复制文件到发布目录"""
        if not source_path.exists():
            return None

        # 创建发布目录结构
        dirs = self.create_release_structure(version_info)

        # 生成新文件名
        new_filename = self.generate_release_filename(build_type, version_info)
        target_path = dirs['windows_dir'] / new_filename

        # 复制文件
        import shutil
        shutil.copy2(source_path, target_path)

        print(f"📦 已复制到发布目录: {target_path}")

        # 创建版本信息文件
        self.create_version_info_file(dirs['windows_dir'], build_type, version_info, new_filename)

        return target_path

    def create_version_info_file(self, target_dir, build_type, version_info, filename):
        """创建版本信息文件"""
        import json
        from datetime import datetime

        info = {
            "app_name": "CharAsGem",
            "version": f"{version_info['major']}.{version_info['minor']}.{version_info['patch']}",
            "build_number": version_info['build'],
            "full_version": f"{version_info['major']}.{version_info['minor']}.{version_info['patch']}+{version_info['build']}",
            "platform": "windows",
            "architecture": "x64",
            "build_type": build_type,
            "filename": filename,
            "build_date": datetime.now().isoformat(),
            "file_size": self.get_file_info(target_dir / filename)['size'] if (target_dir / filename).exists() else "Unknown"
        }

        info_file = target_dir / f"{filename}.info.json"
        with open(info_file, 'w', encoding='utf-8') as f:
            json.dump(info, f, ensure_ascii=False, indent=2)

        print(f"📋 已创建版本信息文件: {info_file}")
    
    def build_msix(self):
        """构建 MSIX 安装包"""
        print("\n🚀 构建 MSIX 安装包...")
        print("="*60)
        
        # 清理项目
        if not self.run_command("flutter clean", "清理项目"):
            return False
        
        # 获取依赖
        if not self.run_command("flutter pub get", "获取依赖"):
            return False
        
        # 构建 Windows Release
        if not self.run_command("flutter build windows --release", "构建 Windows Release"):
            return False
        
        # 创建 MSIX 安装包
        if not self.run_command("flutter pub run msix:create", "创建 MSIX 安装包"):
            return False
        
        # 检查输出文件（MSIX文件名基于项目名称，不是显示名称）
        msix_path = self.project_root / "build" / "windows" / "x64" / "runner" / "Release" / "charasgem.msix"
        file_info = self.get_file_info(msix_path)

        if file_info:
            print("\n🎉 MSIX 安装包构建成功!")
            print(f"📂 原始位置: {file_info['path']}")
            print(f"📊 文件大小: {file_info['size']}")

            # 复制到发布目录
            version_info = self.load_current_version()
            if version_info:
                release_path = self.copy_to_releases(msix_path, 'msix', version_info)
                if release_path:
                    print(f"✅ 发布文件: {release_path}")
        else:
            print("❌ 未找到 MSIX 安装包文件")
            return False

        return True
    
    def build_portable(self):
        """构建便携版可执行文件"""
        print("\n📦 构建便携版应用...")
        print("="*60)

        # 清理项目
        if not self.run_command("flutter clean", "清理项目"):
            return False

        # 获取依赖
        if not self.run_command("flutter pub get", "获取依赖"):
            return False

        # 构建 Windows Release
        if not self.run_command("flutter build windows --release", "构建 Windows Release"):
            return False

        # 检查 Release 目录
        release_dir = self.project_root / "build" / "windows" / "x64" / "runner" / "Release"
        exe_path = release_dir / "charasgem.exe"

        if not exe_path.exists():
            print("❌ 未找到可执行文件")
            return False

        print("\n🎉 便携版构建成功!")
        print(f"📂 Release 目录: {release_dir}")

        # 打包整个 Release 目录为 ZIP 文件
        version_info = self.load_current_version()
        if version_info:
            zip_path = self.create_portable_zip(release_dir, version_info)
            if zip_path:
                print(f"✅ 便携版 ZIP: {zip_path}")

        return True

    def create_portable_zip(self, release_dir, version_info):
        """创建便携版 ZIP 文件"""
        import zipfile
        import os
        from datetime import datetime

        # 创建发布目录结构
        dirs = self.create_release_structure(version_info)

        # 生成 ZIP 文件名
        zip_filename = self.generate_release_filename('portable', version_info).replace('.exe', '.zip')
        zip_path = dirs['windows_dir'] / zip_filename

        print(f"🔄 打包便携版到: {zip_filename}")

        try:
            with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                # 遍历 Release 目录中的所有文件
                for root, dirs_list, files in os.walk(release_dir):
                    for file in files:
                        file_path = Path(root) / file
                        # 计算相对路径
                        arcname = file_path.relative_to(release_dir)
                        zipf.write(file_path, arcname)

                # 添加启动脚本
                startup_script = """@echo off
title CharAsGem
cd /d "%~dp0"
start "" "charasgem.exe"
"""
                zipf.writestr("启动应用.bat", startup_script.encode('utf-8'))

                # 添加说明文件
                readme_content = f"""# CharAsGem 便携版

版本: {version_info['major']}.{version_info['minor']}.{version_info['patch']}
构建号: {version_info['build']}
构建日期: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 使用方法

1. 解压此 ZIP 文件到任意目录
2. 双击 "启动应用.bat" 或直接运行 "charasgem.exe"

## 文件说明

- charasgem.exe: 主程序
- data/: 应用数据和资源文件
- *.dll: 必需的动态链接库
- 启动应用.bat: 便捷启动脚本

## 注意事项

- 请保持所有文件在同一目录下
- 不要删除任何文件，否则可能导致程序无法运行
"""
                zipf.writestr("README.txt", readme_content.encode('utf-8'))

            # 获取 ZIP 文件信息
            zip_size_mb = zip_path.stat().st_size / (1024 * 1024)
            print(f"📊 ZIP 文件大小: {zip_size_mb:.2f} MB")

            # 创建版本信息文件
            self.create_version_info_file(dirs['windows_dir'], 'portable', version_info, zip_filename)

            return zip_path

        except Exception as e:
            print(f"❌ 创建 ZIP 文件失败: {e}")
            return None
    
    def show_menu(self):
        """显示交互式菜单"""
        while True:
            os.system('cls' if os.name == 'nt' else 'clear')
            
            print("🪟 字字珠玑 - Windows 构建工具")
            print("="*60)
            
            self.show_current_version()
            
            print("\n📋 构建选项:")
            print("1. 🚀 构建 MSIX 安装包")
            print("2. 📦 构建便携版可执行文件")
            print("3. 🔄 更新构建号并构建 MSIX")
            print("4. 🔧 升级补丁版本并构建 MSIX")
            print("5. 🚀 升级次版本并构建 MSIX")
            print("6. 🎉 升级主版本并构建 MSIX")
            print("7. 📋 仅更新版本号")
            print("0. 🚪 退出")
            
            print("\n" + "="*60)
            choice = input("请选择操作 (0-7): ").strip()
            
            if choice == '0':
                print("\n👋 再见！")
                break
            elif choice == '1':
                self.build_msix()
                input("\n按回车键继续...")
            elif choice == '2':
                self.build_portable()
                input("\n按回车键继续...")
            elif choice == '3':
                if self.update_version('build'):
                    self.show_current_version()
                    self.build_msix()
                input("\n按回车键继续...")
            elif choice == '4':
                if self.update_version('patch'):
                    self.show_current_version()
                    self.build_msix()
                input("\n按回车键继续...")
            elif choice == '5':
                if self.update_version('minor'):
                    self.show_current_version()
                    self.build_msix()
                input("\n按回车键继续...")
            elif choice == '6':
                if self.update_version('major'):
                    self.show_current_version()
                    self.build_msix()
                input("\n按回车键继续...")
            elif choice == '7':
                print("\n📋 版本更新选项:")
                print("1. 🔄 更新构建号")
                print("2. 🔧 升级补丁版本")
                print("3. 🚀 升级次版本")
                print("4. 🎉 升级主版本")
                
                version_choice = input("请选择版本更新类型 (1-4): ").strip()
                version_types = {'1': 'build', '2': 'patch', '3': 'minor', '4': 'major'}
                
                if version_choice in version_types:
                    self.update_version(version_types[version_choice])
                else:
                    print("❌ 无效选择")
                input("\n按回车键继续...")
            else:
                print("❌ 无效选择，请重新输入")
                input("\n按回车键继续...")

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='字字珠玑 Windows 构建工具')
    parser.add_argument('--type', choices=['msix', 'portable'], default='msix',
                       help='构建类型 (默认: msix)')
    parser.add_argument('--update-version', choices=['build', 'patch', 'minor', 'major'],
                       help='构建前更新版本号')
    parser.add_argument('--interactive', action='store_true',
                       help='启动交互式菜单')
    
    args = parser.parse_args()
    
    try:
        builder = WindowsBuilder()
        
        if args.interactive or len(sys.argv) == 1:
            # 交互式菜单模式
            builder.show_menu()
        else:
            # 命令行模式
            builder.show_current_version()
            
            # 更新版本（如果指定）
            if args.update_version:
                if not builder.update_version(args.update_version):
                    sys.exit(1)
                builder.show_current_version()
            
            # 执行构建
            if args.type == 'msix':
                success = builder.build_msix()
            elif args.type == 'portable':
                success = builder.build_portable()
            else:
                print(f"❌ 未知的构建类型: {args.type}")
                sys.exit(1)
            
            if not success:
                sys.exit(1)
                
    except KeyboardInterrupt:
        print("\n\n👋 用户中断，再见！")
    except Exception as e:
        print(f"\n❌ 程序出错: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
