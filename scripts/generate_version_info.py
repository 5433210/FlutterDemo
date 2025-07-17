#!/usr/bin/env python3
"""
版本信息自动生成脚本
负责生成和更新项目版本信息，支持多平台版本号管理
"""

import os
import sys
import json
import yaml
import argparse
import subprocess
from datetime import datetime
from pathlib import Path

# 尝试导入pytz，如果不存在则使用标准库
try:
    import pytz
    HAS_PYTZ = True
except ImportError:
    HAS_PYTZ = False
    print("警告: 未安装pytz，将使用系统本地时间")

class VersionGenerator:
    """版本信息生成器"""
    
    def __init__(self, project_root=None):
        """初始化版本生成器
        
        Args:
            project_root: 项目根目录路径
        """
        self.project_root = Path(project_root) if project_root else Path(__file__).parent.parent
        self.version_config_file = self.project_root / 'version.yaml'
        self.pubspec_file = self.project_root / 'pubspec.yaml'
        
    def load_version_config(self):
        """加载版本配置文件"""
        try:
            with open(self.version_config_file, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            print(f"错误: 版本配置文件 {self.version_config_file} 不存在")
            return None
        except yaml.YAMLError as e:
            print(f"错误: 解析版本配置文件失败: {e}")
            return None
    
    def save_version_config(self, config):
        """保存版本配置文件"""
        try:
            with open(self.version_config_file, 'w', encoding='utf-8') as f:
                yaml.safe_dump(config, f, default_flow_style=False, allow_unicode=True)
            return True
        except Exception as e:
            print(f"错误: 保存版本配置文件失败: {e}")
            return False
    
    def get_git_info(self):
        """获取Git信息"""
        git_info = {
            'commit': None,
            'branch': None,
            'tag': None,
            'is_dirty': False
        }
        
        try:
            # 获取当前提交哈希
            result = subprocess.run(['git', 'rev-parse', 'HEAD'],
                                  capture_output=True, text=True, cwd=self.project_root)
            if result.returncode == 0 and result.stdout:
                git_info['commit'] = result.stdout.strip()[:8]  # 取前8位

            # 获取当前分支
            result = subprocess.run(['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
                                  capture_output=True, text=True, cwd=self.project_root)
            if result.returncode == 0 and result.stdout:
                git_info['branch'] = result.stdout.strip()

            # 获取最新标签
            result = subprocess.run(['git', 'describe', '--tags', '--abbrev=0'],
                                  capture_output=True, text=True, cwd=self.project_root)
            if result.returncode == 0 and result.stdout:
                git_info['tag'] = result.stdout.strip()

            # 检查是否有未提交的更改
            result = subprocess.run(['git', 'status', '--porcelain'],
                                  capture_output=True, text=True, cwd=self.project_root)
            if result.returncode == 0 and result.stdout is not None:
                git_info['is_dirty'] = bool(result.stdout.strip())
                
        except Exception as e:
            print(f"警告: 获取Git信息失败: {e}")
        
        return git_info
    
    def generate_build_number(self, timezone='Asia/Shanghai'):
        """生成构建号
        
        Args:
            timezone: 时区
            
        Returns:
            str: 格式为 YYYYMMDDXXX 的构建号
        """
        try:
            if HAS_PYTZ:
                tz = pytz.timezone(timezone)
                now = datetime.now(tz)
            else:
                now = datetime.now()
                
            date_str = now.strftime('%Y%m%d')
            
            # 查找当日已有的构建号
            existing_builds = self._find_existing_builds(date_str)
            next_sequence = max(existing_builds) + 1 if existing_builds else 1
            
            return f"{date_str}{next_sequence:03d}"
            
        except Exception as e:
            print(f"警告: 生成构建号失败: {e}, 使用默认值")
            return datetime.now().strftime('%Y%m%d001')
    
    def _find_existing_builds(self, date_str):
        """查找指定日期的已有构建号"""
        builds = []
        
        # 可以从Git标签、构建历史等地方查找
        try:
            result = subprocess.run(['git', 'tag', '-l', f'*{date_str}*'], 
                                  capture_output=True, text=True, cwd=self.project_root)
            if result.returncode == 0:
                for tag in result.stdout.strip().split('\n'):
                    if tag and date_str in tag:
                        # 提取序号
                        try:
                            sequence = int(tag[-3:])
                            builds.append(sequence)
                        except ValueError:
                            continue
        except Exception:
            pass
        
        return builds
    
    def increment_version(self, version_type='patch'):
        """递增版本号
        
        Args:
            version_type: 版本类型 (major, minor, patch)
        """
        config = self.load_version_config()
        if not config:
            return False
        
        version = config.get('version', {})
        
        if version_type == 'major':
            version['major'] = version.get('major', 1) + 1
            version['minor'] = 0
            version['patch'] = 0
        elif version_type == 'minor':
            version['minor'] = version.get('minor', 0) + 1
            version['patch'] = 0
        elif version_type == 'patch':
            version['patch'] = version.get('patch', 0) + 1
        
        # 生成新的构建号
        version['build'] = self.generate_build_number()
        
        config['version'] = version
        return self.save_version_config(config)
    
    def set_version(self, major=None, minor=None, patch=None, prerelease=None):
        """设置版本号
        
        Args:
            major: 主版本号
            minor: 次版本号
            patch: 修订版本号
            prerelease: 预发布标识符
        """
        config = self.load_version_config()
        if not config:
            return False
        
        version = config.get('version', {})
        
        if major is not None:
            version['major'] = major
        if minor is not None:
            version['minor'] = minor
        if patch is not None:
            version['patch'] = patch
        if prerelease is not None:
            version['prerelease'] = prerelease
        
        # 生成新的构建号
        version['build'] = self.generate_build_number()
        
        config['version'] = version
        return self.save_version_config(config)
    
    def generate_version_info(self):
        """生成完整版本信息"""
        config = self.load_version_config()
        if not config:
            return None
        
        version = config.get('version', {})
        git_info = self.get_git_info()
        
        # 构建完整版本信息
        version_info = {
            'version': version,
            'git': git_info,
            'build_time': datetime.now().isoformat(),
            'platforms': self._generate_platform_versions(version)
        }
        
        return version_info
    
    def _generate_platform_versions(self, version):
        """生成平台特定版本信息"""
        major = version.get('major', 1)
        minor = version.get('minor', 0)
        patch = version.get('patch', 0)
        prerelease = version.get('prerelease', '')
        build = version.get('build', '20250620001')
        
        # 构建版本字符串
        version_string = f"{major}.{minor}.{patch}"
        if prerelease:
            version_string += f"-{prerelease}"
        
        platforms = {
            'android': {
                'versionName': version_string,
                'versionCode': int(build)
            },
            'ios': {
                'CFBundleShortVersionString': version_string,
                'CFBundleVersion': build
            },
            'ohos': {
                'versionName': version_string,
                'versionCode': int(build)
            },
            'web': {
                'version': version_string,
                'version_name': f"{version_string}-{build}"
            },
            'windows': {
                'FileVersion': f"{major}.{minor}.{patch}.{build}",
                'ProductVersion': f"{major}.{minor}.{patch}.{build}"
            },
            'macos': {
                'CFBundleShortVersionString': version_string,
                'CFBundleVersion': build
            },
            'linux': {
                'APP_VERSION_MAJOR': major,
                'APP_VERSION_MINOR': minor,
                'APP_VERSION_PATCH': patch,
                'APP_BUILD_NUMBER': build,
                'APP_VERSION_STRING': f"{version_string}-{build}"
            }
        }
        
        return platforms
    
    def update_pubspec(self):
        """更新pubspec.yaml文件"""
        config = self.load_version_config()
        if not config:
            return False
        
        version = config.get('version', {})
        major = version.get('major', 1)
        minor = version.get('minor', 0)
        patch = version.get('patch', 0)
        build = version.get('build', '20250620001')
        
        version_string = f"{major}.{minor}.{patch}+{build}"
        
        try:
            # 读取pubspec.yaml
            with open(self.pubspec_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 替换版本号
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if line.startswith('version:'):
                    lines[i] = f'version: {version_string}'
                    break
            
            # 写回文件
            with open(self.pubspec_file, 'w', encoding='utf-8') as f:
                f.write('\n'.join(lines))
            
            print(f"已更新 pubspec.yaml 版本号: {version_string}")
            return True
            
        except Exception as e:
            print(f"错误: 更新pubspec.yaml失败: {e}")
            return False
    
    def update_platform_versions(self):
        """更新所有平台的版本信息"""
        version_info = self.generate_version_info()
        if not version_info:
            return False
        
        platforms = version_info['platforms']
        success = True
        
        # 更新Android平台
        if self._update_android_version(platforms['android']):
            print("√ Android平台版本更新成功")
        else:
            print("× Android平台版本更新失败")
            success = False

        # 更新iOS平台
        if self._update_ios_version(platforms['ios']):
            print("√ iOS平台版本更新成功")
        else:
            print("× iOS平台版本更新失败")
            success = False

        # 更新鸿蒙OS平台
        if self._update_ohos_version(platforms['ohos']):
            print("√ 鸿蒙OS平台版本更新成功")
        else:
            print("× 鸿蒙OS平台版本更新失败")
            success = False

        # 更新Web平台
        if self._update_web_version(platforms['web']):
            print("√ Web平台版本更新成功")
        else:
            print("× Web平台版本更新失败")
            success = False

        # 更新Windows平台
        if self._update_windows_version(platforms['windows']):
            print("√ Windows平台版本更新成功")
        else:
            print("× Windows平台版本更新失败")
            success = False

        # 更新macOS平台
        if self._update_macos_version(platforms['macos']):
            print("√ macOS平台版本更新成功")
        else:
            print("× macOS平台版本更新失败")
            success = False

        # 更新Linux平台
        if self._update_linux_version(platforms['linux']):
            print("√ Linux平台版本更新成功")
        else:
            print("× Linux平台版本更新失败")
            success = False
        
        return success
    
    def _update_android_version(self, version_info):
        """更新Android平台版本"""
        try:
            # 调用Android平台更新脚本
            script_path = self.project_root / 'scripts' / 'platform' / 'update_android_version.py'
            if script_path.exists():
                result = subprocess.run([
                    sys.executable, str(script_path),
                    str(self.project_root),
                    version_info['versionName'],
                    str(version_info['versionCode'])
                ], capture_output=True, text=True)
                return result.returncode == 0
            else:
                print(f"警告: Android更新脚本不存在: {script_path}")
                return False
        except Exception as e:
            print(f"Android版本更新失败: {e}")
            return False
    
    def _update_ios_version(self, version_info):
        """更新iOS平台版本"""
        try:
            # 调用iOS平台更新脚本
            script_path = self.project_root / 'scripts' / 'platform' / 'update_ios_version.py'
            if script_path.exists():
                result = subprocess.run([
                    sys.executable, str(script_path),
                    str(self.project_root),
                    str(version_info['CFBundleShortVersionString']),
                    str(version_info['CFBundleVersion'])
                ], capture_output=True, text=True)
                return result.returncode == 0
            else:
                print(f"警告: iOS更新脚本不存在: {script_path}")
                return False
        except Exception as e:
            print(f"iOS版本更新失败: {e}")
            return False
    
    def _update_ohos_version(self, version_info):
        """更新鸿蒙OS平台版本"""
        try:
            # 调用鸿蒙OS平台更新脚本
            script_path = self.project_root / 'scripts' / 'platform' / 'update_ohos_version.py'
            if script_path.exists():
                result = subprocess.run([
                    sys.executable, str(script_path),
                    str(self.project_root),
                    version_info['versionName'],
                    str(version_info['versionCode'])
                ], capture_output=True, text=True)
                return result.returncode == 0
            else:
                print(f"警告: 鸿蒙OS更新脚本不存在: {script_path}")
                return False
        except Exception as e:
            print(f"鸿蒙OS版本更新失败: {e}")
            return False
    
    def _update_web_version(self, version_info):
        """更新Web平台版本"""
        try:
            # 直接更新web/manifest.json
            manifest_path = self.project_root / 'web' / 'manifest.json'
            if manifest_path.exists():
                with open(manifest_path, 'r', encoding='utf-8') as f:
                    manifest = json.load(f)
                
                manifest['version'] = version_info['version']
                manifest['version_name'] = version_info['version_name']
                
                with open(manifest_path, 'w', encoding='utf-8') as f:
                    json.dump(manifest, f, indent=2, ensure_ascii=False)
                
                return True
            else:
                print(f"警告: Web manifest文件不存在: {manifest_path}")
                return False
        except Exception as e:
            print(f"Web版本更新失败: {e}")
            return False
    
    def _update_windows_version(self, version_info):
        """更新Windows平台版本"""
        try:
            # 调用Windows平台更新脚本
            script_path = self.project_root / 'scripts' / 'platform' / 'update_windows_version.py'
            if script_path.exists():
                result = subprocess.run([
                    sys.executable, str(script_path),
                    str(self.project_root),
                    version_info['FileVersion'],
                    version_info['ProductVersion']
                ], capture_output=True, text=True)
                return result.returncode == 0
            else:
                print(f"警告: Windows更新脚本不存在: {script_path}")
                return False
        except Exception as e:
            print(f"Windows版本更新失败: {e}")
            return False
    
    def _update_macos_version(self, version_info):
        """更新macOS平台版本"""
        try:
            # 调用macOS平台更新脚本
            script_path = self.project_root / 'scripts' / 'platform' / 'update_macos_version.py'
            if script_path.exists():
                result = subprocess.run([
                    sys.executable, str(script_path),
                    str(self.project_root),
                    str(version_info['CFBundleShortVersionString']),
                    str(version_info['CFBundleVersion'])
                ], capture_output=True, text=True)
                return result.returncode == 0
            else:
                print(f"警告: macOS更新脚本不存在: {script_path}")
                return False
        except Exception as e:
            print(f"macOS版本更新失败: {e}")
            return False
    
    def _update_linux_version(self, version_info):
        """更新Linux平台版本"""
        try:
            # 调用Linux平台更新脚本
            script_path = self.project_root / 'scripts' / 'platform' / 'update_linux_version.py'
            if script_path.exists():
                result = subprocess.run([
                    sys.executable, str(script_path),
                    str(self.project_root),
                    str(version_info['APP_VERSION_MAJOR']),
                    str(version_info['APP_VERSION_MINOR']),
                    str(version_info['APP_VERSION_PATCH']),
                    str(version_info['APP_BUILD_NUMBER'])
                ], capture_output=True, text=True)
                return result.returncode == 0
            else:
                print(f"警告: Linux更新脚本不存在: {script_path}")
                return False
        except Exception as e:
            print(f"Linux版本更新失败: {e}")
            return False

    def save_version_json(self, output_file='version.json'):
        """保存版本信息到JSON文件"""
        version_info = self.generate_version_info()
        if not version_info:
            return False
        
        try:
            output_path = self.project_root / output_file
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(version_info, f, indent=2, ensure_ascii=False)
            
            print(f"版本信息已保存到: {output_path}")
            return True
            
        except Exception as e:
            print(f"错误: 保存版本信息失败: {e}")
            return False


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='版本信息生成脚本')
    parser.add_argument('--increment', choices=['major', 'minor', 'patch'], 
                       help='递增版本号')
    parser.add_argument('--set-version', help='设置版本号 (格式: 1.2.3)')
    parser.add_argument('--prerelease', help='设置预发布标识符')
    parser.add_argument('--output', default='version.json', 
                       help='输出文件名 (默认: version.json)')
    parser.add_argument('--project-root', help='项目根目录')
    
    args = parser.parse_args()
    
    # 初始化版本生成器
    generator = VersionGenerator(args.project_root)
    
    # 处理版本号操作
    if args.increment:
        print(f"递增 {args.increment} 版本号...")
        if generator.increment_version(args.increment):
            print("版本号递增成功")
        else:
            print("版本号递增失败")
            sys.exit(1)
    
    if args.set_version:
        try:
            parts = args.set_version.split('.')
            major, minor, patch = int(parts[0]), int(parts[1]), int(parts[2])
            print(f"设置版本号: {major}.{minor}.{patch}")
            if generator.set_version(major, minor, patch, args.prerelease):
                print("版本号设置成功")
            else:
                print("版本号设置失败")
                sys.exit(1)
        except (ValueError, IndexError):
            print("错误: 版本号格式不正确，应为 major.minor.patch")
            sys.exit(1)
    
    # 更新配置文件
    print("更新项目配置文件...")
    if not generator.update_pubspec():
        print("更新pubspec.yaml失败")
        sys.exit(1)
    
    # 更新所有平台版本信息
    print("更新所有平台版本信息...")
    if not generator.update_platform_versions():
        print("警告: 部分平台版本更新失败，但继续执行")
    
    # 生成版本信息文件
    print("生成版本信息文件...")
    if not generator.save_version_json(args.output):
        print("生成版本信息文件失败")
        sys.exit(1)
    
    print("版本信息生成完成!")


if __name__ == '__main__':
    main() 