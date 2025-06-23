#!/usr/bin/env python3
"""
macOS平台构建脚本
支持APP/DMG构建、应用公证、Mac App Store上传等
"""

import os
import sys
import subprocess
import argparse
import json
import shutil
import plistlib
from pathlib import Path
from datetime import datetime

class macOSBuilder:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.macos_dir = self.project_root / "macos"
        self.build_dir = self.project_root / "build" / "macos"
        self.output_dir = self.project_root / "releases" / "macos"
        
        # 确保输出目录存在
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def check_environment(self):
        """检查macOS构建环境"""
        print("🔍 检查macOS构建环境...")
        
        # 检查macOS
        if sys.platform != "darwin":
            print("❌ macOS构建需要在macOS系统上进行")
            return False
            
        # 检查Flutter
        try:
            result = subprocess.run(['flutter', '--version'], 
                                  capture_output=True, text=True, check=True)
            flutter_version = result.stdout.split()[1]
            print(f"✅ Flutter: {flutter_version}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("❌ Flutter未安装或不在PATH中")
            return False
            
        # 检查Xcode
        try:
            result = subprocess.run(['xcodebuild', '-version'], 
                                  capture_output=True, text=True, check=True)
            xcode_version = result.stdout.split('\n')[0]
            print(f"✅ {xcode_version}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("❌ Xcode未安装或命令行工具未配置")
            return False
            
        # 检查CocoaPods
        try:
            result = subprocess.run(['pod', '--version'], 
                                  capture_output=True, text=True, check=True)
            print(f"✅ CocoaPods: {result.stdout.strip()}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("❌ CocoaPods未安装")
            return False
            
        # 检查create-dmg工具
        try:
            result = subprocess.run(['create-dmg', '--version'], 
                                  capture_output=True, text=True, check=True)
            print("✅ create-dmg可用")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("⚠️ create-dmg未安装 (brew install create-dmg)")
            
        return True
        
    def clean_build(self):
        """清理构建缓存"""
        print("🧹 清理构建缓存...")
        
        # Flutter clean
        subprocess.run(['flutter', 'clean'], cwd=self.project_root)
        
        # Xcode clean
        subprocess.run(['xcodebuild', 'clean', '-workspace', 'Runner.xcworkspace', 
                       '-scheme', 'Runner'], cwd=self.macos_dir)
        
        # 清理Pods
        pods_dir = self.macos_dir / "Pods"
        if pods_dir.exists():
            shutil.rmtree(pods_dir)
            
        # 清理DerivedData
        derived_data_dir = Path.home() / "Library" / "Developer" / "Xcode" / "DerivedData"
        if derived_data_dir.exists():
            for item in derived_data_dir.iterdir():
                if "Runner" in item.name:
                    shutil.rmtree(item)
                    
        # 删除构建目录
        if self.build_dir.exists():
            shutil.rmtree(self.build_dir)
            
        print("✅ 构建缓存已清理")
        
    def update_pods(self):
        """更新CocoaPods依赖"""
        print("📦 更新CocoaPods依赖...")
        
        try:
            # 安装/更新Pods
            result = subprocess.run(['pod', 'install', '--repo-update'], 
                                  cwd=self.macos_dir, check=True)
            print("✅ CocoaPods依赖更新成功")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ CocoaPods依赖更新失败: {e}")
            return False
            
    def get_version_info(self):
        """获取版本信息"""
        try:
            with open(self.project_root / "pubspec.yaml", "r", encoding="utf-8") as f:
                content = f.read()
                for line in content.split('\n'):
                    if line.startswith('version:'):
                        version_line = line.split(':', 1)[1].strip()
                        if '+' in version_line:
                            version, build = version_line.split('+')
                            return version, build
                        else:
                            return version_line, "1"
        except Exception as e:
            print(f"⚠️ 无法读取版本信息: {e}")
            return "1.0.0", "1"
            
    def update_build_settings(self):
        """更新构建设置"""
        print("⚙️ 更新构建设置...")
        
        version, build_number = self.get_version_info()
        build_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # 获取Git提交信息
        try:
            git_commit = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'], 
                                      capture_output=True, text=True, check=True).stdout.strip()
        except:
            git_commit = "unknown"
            
        # 更新Info.plist中的构建信息
        info_plist_path = self.macos_dir / "Runner" / "Info.plist"
        if info_plist_path.exists():
            with open(info_plist_path, 'rb') as f:
                plist_data = plistlib.load(f)
                
            # 更新构建信息
            plist_data['BuildDate'] = build_date
            plist_data['GitCommit'] = git_commit
            plist_data['CFBundleShortVersionString'] = version
            plist_data['CFBundleVersion'] = build_number
            
            with open(info_plist_path, 'wb') as f:
                plistlib.dump(plist_data, f)
                
        print(f"✅ 构建设置已更新 - 版本: {version}, 构建号: {build_number}")
        
    def build_macos(self, configuration="Release"):
        """构建macOS应用"""
        print(f"🔨 构建macOS应用 - {configuration}...")
        
        # 更新Pods
        if not self.update_pods():
            return False
            
        # 更新构建设置
        self.update_build_settings()
        
        cmd = ['flutter', 'build', 'macos']
        
        # 构建配置
        if configuration.lower() == "debug":
            cmd.append('--debug')
        elif configuration.lower() == "profile":
            cmd.append('--profile')
        else:
            cmd.append('--release')
            
        # 执行构建
        try:
            result = subprocess.run(cmd, cwd=self.project_root, check=True)
            print("✅ macOS构建成功")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ macOS构建失败: {e}")
            return False
            
    def sign_app(self, app_path, identity=None):
        """签名应用"""
        print("🔐 签名应用...")
        
        if not identity:
            identity = os.environ.get('MACOS_SIGNING_IDENTITY')
            
        if not identity:
            print("⚠️ 签名身份未配置，跳过签名")
            return True
            
        try:
            # 深度签名
            cmd = [
                'codesign', '--deep', '--force', '--verify', '--verbose',
                '--sign', identity,
                '--options', 'runtime',  # 启用强化运行时
                str(app_path)
            ]
            
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print("✅ 应用签名成功")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ 应用签名失败: {e}")
            print(f"错误输出: {e.stderr}")
            return False
            
    def notarize_app(self, app_path):
        """公证应用"""
        print("📋 公证应用...")
        
        # 检查公证配置
        apple_id = os.environ.get('APPLE_ID')
        app_password = os.environ.get('APP_SPECIFIC_PASSWORD')
        team_id = os.environ.get('APPLE_TEAM_ID')
        
        if not all([apple_id, app_password, team_id]):
            print("⚠️ 公证配置不完整，跳过公证")
            return True
            
        try:
            # 创建ZIP文件用于公证
            zip_path = app_path.with_suffix('.zip')
            cmd = ['ditto', '-c', '-k', '--keepParent', str(app_path), str(zip_path)]
            subprocess.run(cmd, check=True)
            
            # 提交公证
            cmd = [
                'xcrun', 'notarytool', 'submit', str(zip_path),
                '--apple-id', apple_id,
                '--password', app_password,
                '--team-id', team_id,
                '--wait'
            ]
            
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print("✅ 应用公证成功")
            
            # 装订公证票据
            cmd = ['xcrun', 'stapler', 'staple', str(app_path)]
            subprocess.run(cmd, check=True)
            print("✅ 公证票据已装订")
            
            # 清理ZIP文件
            zip_path.unlink()
            
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ 应用公证失败: {e}")
            print(f"错误输出: {e.stderr}")
            return False
            
    def create_dmg(self, app_path):
        """创建DMG安装包"""
        print("💿 创建DMG安装包...")
        
        version, build_number = self.get_version_info()
        dmg_name = f"CharasGem-v{version}-{build_number}.dmg"
        dmg_path = self.output_dir / dmg_name
        
        # 删除已存在的DMG文件
        if dmg_path.exists():
            dmg_path.unlink()
            
        try:
            cmd = [
                'create-dmg',
                '--volname', f'CharasGem {version}',
                '--volicon', str(self.macos_dir / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset' / 'app_icon_512.png'),
                '--window-pos', '200', '120',
                '--window-size', '600', '400',
                '--icon-size', '100',
                '--icon', app_path.name, '175', '120',
                '--hide-extension', app_path.name,
                '--app-drop-link', '425', '120',
                '--background', str(self.create_dmg_background()),
                str(dmg_path),
                str(app_path.parent)
            ]
            
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print(f"✅ DMG创建成功: {dmg_path}")
            return dmg_path
            
        except subprocess.CalledProcessError as e:
            print(f"❌ DMG创建失败: {e}")
            print(f"错误输出: {e.stderr}")
            return None
            
    def create_dmg_background(self):
        """创建DMG背景图片"""
        # 这里应该返回实际的背景图片路径
        # 为了演示，返回一个占位符路径
        bg_path = self.build_dir / "dmg_background.png"
        bg_path.parent.mkdir(parents=True, exist_ok=True)
        
        if not bg_path.exists():
            # 创建一个简单的背景（实际应用中应该使用设计好的图片）
            bg_path.write_text("# DMG Background Placeholder")
            
        return bg_path
        
    def sign_dmg(self, dmg_path, identity=None):
        """签名DMG文件"""
        print("🔐 签名DMG文件...")
        
        if not identity:
            identity = os.environ.get('MACOS_SIGNING_IDENTITY')
            
        if not identity:
            print("⚠️ 签名身份未配置，跳过DMG签名")
            return True
            
        try:
            cmd = [
                'codesign', '--sign', identity,
                '--verbose',
                str(dmg_path)
            ]
            
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print("✅ DMG签名成功")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ DMG签名失败: {e}")
            print(f"错误输出: {e.stderr}")
            return False
            
    def organize_outputs(self, configuration="Release"):
        """整理构建产物"""
        print("📦 整理构建产物...")
        
        version, build_number = self.get_version_info()
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 目标目录
        target_dir = self.output_dir / f"v{version}_build{build_number}_{timestamp}"
        target_dir.mkdir(parents=True, exist_ok=True)
        
        # 复制APP文件
        app_source_dir = self.project_root / "build" / "macos" / "Build" / "Products" / configuration / "demo.app"
        if app_source_dir.exists():
            app_target_dir = target_dir / "demo.app"
            shutil.copytree(app_source_dir, app_target_dir)
            print(f"📱 APP: {app_target_dir}")
            
        # 复制DMG文件
        dmg_files = list(self.output_dir.glob("*.dmg"))
        for dmg_file in dmg_files:
            if dmg_file.parent == self.output_dir:  # 只复制根目录下的DMG文件
                target_dmg = target_dir / dmg_file.name
                shutil.copy2(dmg_file, target_dmg)
                print(f"💿 DMG: {target_dmg}")
                dmg_file.unlink()  # 删除原文件
                
        # 生成构建信息
        build_info = {
            "platform": "macOS",
            "version": version,
            "build_number": build_number,
            "configuration": configuration,
            "timestamp": timestamp,
            "files": [f.name for f in target_dir.iterdir()]
        }
        
        with open(target_dir / "build_info.json", "w", encoding="utf-8") as f:
            json.dump(build_info, f, indent=2, ensure_ascii=False)
            
        print(f"✅ 构建产物已整理到: {target_dir}")
        return target_dir
        
    def upload_to_app_store(self, app_path):
        """上传到Mac App Store"""
        print("🚀 上传到Mac App Store...")
        
        # 检查必要的环境变量
        api_key_id = os.environ.get('APP_STORE_CONNECT_API_KEY_ID')
        api_issuer_id = os.environ.get('APP_STORE_CONNECT_API_ISSUER_ID')
        api_key_path = os.environ.get('APP_STORE_CONNECT_API_KEY_PATH')
        
        if not all([api_key_id, api_issuer_id, api_key_path]):
            print("⚠️ 缺少App Store Connect API配置，跳过上传")
            return False
            
        try:
            cmd = [
                'xcrun', 'altool', '--upload-app',
                '--type', 'osx',
                '--file', str(app_path),
                '--apiKey', api_key_id,
                '--apiIssuer', api_issuer_id
            ]
            
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print("✅ Mac App Store上传成功")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ Mac App Store上传失败: {e}")
            print(f"错误输出: {e.stderr}")
            return False
            
    def generate_build_report(self):
        """生成构建报告"""
        print("📋 生成构建报告...")
        
        report = {
            "platform": "macOS",
            "timestamp": datetime.now().isoformat(),
            "environment": {
                "xcode_version": self.get_xcode_version(),
                "macos_version": self.get_macos_version(),
                "flutter_version": self.get_flutter_version()
            },
            "builds": []
        }
        
        # 扫描构建产物
        for build_dir in self.output_dir.iterdir():
            if build_dir.is_dir():
                build_info_file = build_dir / "build_info.json"
                if build_info_file.exists():
                    with open(build_info_file, "r", encoding="utf-8") as f:
                        build_info = json.load(f)
                        report["builds"].append(build_info)
                        
        # 保存报告
        report_file = self.output_dir / f"build_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_file, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
            
        print(f"✅ 构建报告已生成: {report_file}")
        return report_file
        
    def get_xcode_version(self):
        """获取Xcode版本"""
        try:
            result = subprocess.run(['xcodebuild', '-version'], 
                                  capture_output=True, text=True, check=True)
            return result.stdout.split('\n')[0]
        except:
            return "Unknown"
            
    def get_macos_version(self):
        """获取macOS版本"""
        try:
            result = subprocess.run(['sw_vers', '-productVersion'], 
                                  capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except:
            return "Unknown"
            
    def get_flutter_version(self):
        """获取Flutter版本"""
        try:
            result = subprocess.run(['flutter', '--version'], 
                                  capture_output=True, text=True, check=True)
            return result.stdout.split()[1]
        except:
            return "Unknown"

def main():
    parser = argparse.ArgumentParser(description="macOS平台构建脚本")
    parser.add_argument("--configuration", choices=["Debug", "Profile", "Release"], 
                       default="Release", help="构建配置")
    parser.add_argument("--output-format", choices=["app", "dmg", "both"], 
                       default="both", help="输出格式")
    parser.add_argument("--signing-identity", help="代码签名身份")
    parser.add_argument("--notarize", action="store_true", 
                       help="公证应用")
    parser.add_argument("--upload-app-store", action="store_true", 
                       help="上传到Mac App Store")
    parser.add_argument("--clean", action="store_true", 
                       help="构建前清理缓存")
    parser.add_argument("--check-env", action="store_true", 
                       help="仅检查构建环境")
    
    args = parser.parse_args()
    
    builder = macOSBuilder()
    
    # 检查环境
    if args.check_env:
        if builder.check_environment():
            print("✅ macOS构建环境检查通过")
            sys.exit(0)
        else:
            print("❌ macOS构建环境检查失败")
            sys.exit(1)
            
    # 环境检查
    if not builder.check_environment():
        print("❌ 构建环境检查失败，请先配置macOS开发环境")
        sys.exit(1)
        
    # 清理构建
    if args.clean:
        builder.clean_build()
        
    # 执行构建
    try:
        # 构建macOS应用
        success = builder.build_macos(args.configuration)
        
        if success:
            app_path = builder.project_root / "build" / "macos" / "Build" / "Products" / args.configuration / "demo.app"
            
            # 签名应用
            if args.signing_identity or os.environ.get('MACOS_SIGNING_IDENTITY'):
                builder.sign_app(app_path, args.signing_identity)
                
                # 公证应用
                if args.notarize:
                    builder.notarize_app(app_path)
                    
            # 创建DMG
            if args.output_format in ["dmg", "both"]:
                dmg_path = builder.create_dmg(app_path)
                if dmg_path and (args.signing_identity or os.environ.get('MACOS_SIGNING_IDENTITY')):
                    builder.sign_dmg(dmg_path, args.signing_identity)
                    
            # 整理输出
            output_dir = builder.organize_outputs(args.configuration)
            
            # 上传到App Store
            if args.upload_app_store:
                builder.upload_to_app_store(app_path)
                
        # 生成构建报告
        builder.generate_build_report()
        
        if success:
            print("\n🎉 macOS构建完成！")
            sys.exit(0)
        else:
            print("\n❌ macOS构建失败！")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n⚠️ 构建被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 构建过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 