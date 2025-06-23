#!/usr/bin/env python3
"""
iOS平台构建脚本
支持IPA构建、证书管理、TestFlight上传等
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

class iOSBuilder:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.ios_dir = self.project_root / "ios"
        self.build_dir = self.project_root / "build" / "ios"
        self.output_dir = self.project_root / "releases" / "ios"
        
        # 确保输出目录存在
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def check_environment(self):
        """检查iOS构建环境"""
        print("🔍 检查iOS构建环境...")
        
        # 检查macOS
        if sys.platform != "darwin":
            print("❌ iOS构建需要在macOS系统上进行")
            return False
            
        # 检查Flutter
        try:
            result = subprocess.run(['flutter', '--version'], 
                                  capture_output=True, text=True, check=True)
            print(f"✅ Flutter: {result.stdout.split()[1]}")
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
            
        # 检查iOS模拟器
        try:
            result = subprocess.run(['xcrun', 'simctl', 'list', 'devices'], 
                                  capture_output=True, text=True, check=True)
            print("✅ iOS模拟器可用")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("⚠️ iOS模拟器不可用")
            
        # 检查CocoaPods
        try:
            result = subprocess.run(['pod', '--version'], 
                                  capture_output=True, text=True, check=True)
            print(f"✅ CocoaPods: {result.stdout.strip()}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("❌ CocoaPods未安装")
            return False
            
        return True
        
    def clean_build(self):
        """清理构建缓存"""
        print("🧹 清理构建缓存...")
        
        # Flutter clean
        subprocess.run(['flutter', 'clean'], cwd=self.project_root)
        
        # Xcode clean
        subprocess.run(['xcodebuild', 'clean', '-workspace', 'Runner.xcworkspace', 
                       '-scheme', 'Runner'], cwd=self.ios_dir)
        
        # 清理Pods
        pods_dir = self.ios_dir / "Pods"
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
                                  cwd=self.ios_dir, check=True)
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
        info_plist_path = self.ios_dir / "Runner" / "Info.plist"
        if info_plist_path.exists():
            with open(info_plist_path, 'rb') as f:
                plist_data = plistlib.load(f)
                
            # 更新构建信息
            plist_data['BuildDate'] = build_date
            plist_data['GitCommit'] = git_commit
            
            with open(info_plist_path, 'wb') as f:
                plistlib.dump(plist_data, f)
                
        print(f"✅ 构建设置已更新 - 版本: {version}, 构建号: {build_number}")
        
    def build_ios(self, configuration="Release", device_type="device"):
        """构建iOS应用"""
        print(f"🔨 构建iOS应用 - {configuration} for {device_type}...")
        
        # 更新Pods
        if not self.update_pods():
            return False
            
        # 更新构建设置
        self.update_build_settings()
        
        cmd = ['flutter', 'build', 'ios']
        
        # 构建配置
        if configuration.lower() == "debug":
            cmd.append('--debug')
        elif configuration.lower() == "profile":
            cmd.append('--profile')
        else:
            cmd.append('--release')
            
        # 设备类型
        if device_type == "simulator":
            cmd.append('--simulator')
        else:
            cmd.append('--no-codesign')  # 暂时不签名，后续单独处理
            
        # 执行构建
        try:
            result = subprocess.run(cmd, cwd=self.project_root, check=True)
            print("✅ iOS构建成功")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ iOS构建失败: {e}")
            return False
            
    def build_ipa(self, configuration="Release", export_method="app-store"):
        """构建IPA文件"""
        print(f"📦 构建IPA文件 - {configuration} ({export_method})...")
        
        # 先构建iOS
        if not self.build_ios(configuration, "device"):
            return False
            
        workspace_path = self.ios_dir / "Runner.xcworkspace"
        archive_path = self.build_dir / "Runner.xcarchive"
        
        # 确保构建目录存在
        self.build_dir.mkdir(parents=True, exist_ok=True)
        
        # 创建Archive
        archive_cmd = [
            'xcodebuild', 'archive',
            '-workspace', str(workspace_path),
            '-scheme', 'Runner',
            '-configuration', configuration,
            '-archivePath', str(archive_path),
            'CODE_SIGNING_ALLOWED=NO'  # 暂时禁用代码签名
        ]
        
        try:
            subprocess.run(archive_cmd, check=True)
            print("✅ Archive创建成功")
        except subprocess.CalledProcessError as e:
            print(f"❌ Archive创建失败: {e}")
            return False
            
        # 导出IPA
        export_options_plist = self.create_export_options_plist(export_method)
        ipa_output_dir = self.build_dir / "ipa"
        ipa_output_dir.mkdir(exist_ok=True)
        
        export_cmd = [
            'xcodebuild', '-exportArchive',
            '-archivePath', str(archive_path),
            '-exportPath', str(ipa_output_dir),
            '-exportOptionsPlist', str(export_options_plist)
        ]
        
        try:
            subprocess.run(export_cmd, check=True)
            print("✅ IPA导出成功")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ IPA导出失败: {e}")
            return False
            
    def create_export_options_plist(self, export_method):
        """创建导出选项plist文件"""
        export_options = {
            'method': export_method,
            'uploadBitcode': False,
            'uploadSymbols': True,
            'compileBitcode': False,
            'stripSwiftSymbols': True,
            'teamID': os.environ.get('IOS_TEAM_ID', ''),
        }
        
        if export_method == 'app-store':
            export_options.update({
                'destination': 'upload',
                'uploadBitcode': False,
            })
        elif export_method == 'ad-hoc':
            export_options.update({
                'destination': 'export',
            })
        elif export_method == 'enterprise':
            export_options.update({
                'destination': 'export',
            })
        elif export_method == 'development':
            export_options.update({
                'destination': 'export',
            })
            
        plist_path = self.build_dir / "ExportOptions.plist"
        with open(plist_path, 'wb') as f:
            plistlib.dump(export_options, f)
            
        return plist_path
        
    def organize_outputs(self, configuration="Release"):
        """整理构建产物"""
        print("📦 整理构建产物...")
        
        version, build_number = self.get_version_info()
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 目标目录
        target_dir = self.output_dir / f"v{version}_build{build_number}_{timestamp}"
        target_dir.mkdir(parents=True, exist_ok=True)
        
        # 复制IPA文件
        ipa_source_dir = self.build_dir / "ipa"
        if ipa_source_dir.exists():
            ipa_files = list(ipa_source_dir.glob("*.ipa"))
            for ipa_file in ipa_files:
                target_ipa = target_dir / ipa_file.name
                shutil.copy2(ipa_file, target_ipa)
                print(f"📄 IPA: {target_ipa}")
                
        # 复制dSYM文件（用于崩溃分析）
        dsym_files = list(ipa_source_dir.glob("*.dSYM"))
        for dsym_file in dsym_files:
            target_dsym = target_dir / dsym_file.name
            shutil.copytree(dsym_file, target_dsym)
            print(f"🔍 dSYM: {target_dsym}")
            
        # 生成构建信息
        build_info = {
            "platform": "iOS",
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
        
    def upload_to_testflight(self, ipa_path):
        """上传到TestFlight"""
        print("🚀 上传到TestFlight...")
        
        # 检查必要的环境变量
        api_key_id = os.environ.get('APP_STORE_CONNECT_API_KEY_ID')
        api_issuer_id = os.environ.get('APP_STORE_CONNECT_API_ISSUER_ID')
        api_key_path = os.environ.get('APP_STORE_CONNECT_API_KEY_PATH')
        
        if not all([api_key_id, api_issuer_id, api_key_path]):
            print("⚠️ 缺少App Store Connect API配置，跳过TestFlight上传")
            return False
            
        cmd = [
            'xcrun', 'altool', '--upload-app',
            '--type', 'ios',
            '--file', str(ipa_path),
            '--apiKey', api_key_id,
            '--apiIssuer', api_issuer_id
        ]
        
        try:
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print("✅ TestFlight上传成功")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ TestFlight上传失败: {e}")
            print(f"错误输出: {e.stderr}")
            return False
            
    def generate_build_report(self):
        """生成构建报告"""
        print("📋 生成构建报告...")
        
        report = {
            "platform": "iOS",
            "timestamp": datetime.now().isoformat(),
            "environment": {
                "xcode_version": self.get_xcode_version(),
                "ios_team_id": os.environ.get('IOS_TEAM_ID', 'Not set'),
                "macos_version": self.get_macos_version()
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

def main():
    parser = argparse.ArgumentParser(description="iOS平台构建脚本")
    parser.add_argument("--configuration", choices=["Debug", "Profile", "Release"], 
                       default="Release", help="构建配置")
    parser.add_argument("--export-method", 
                       choices=["app-store", "ad-hoc", "enterprise", "development"], 
                       default="app-store", help="导出方法")
    parser.add_argument("--device-type", choices=["device", "simulator"], 
                       default="device", help="设备类型")
    parser.add_argument("--upload-testflight", action="store_true", 
                       help="上传到TestFlight")
    parser.add_argument("--clean", action="store_true", 
                       help="构建前清理缓存")
    parser.add_argument("--check-env", action="store_true", 
                       help="仅检查构建环境")
    
    args = parser.parse_args()
    
    builder = iOSBuilder()
    
    # 检查环境
    if args.check_env:
        if builder.check_environment():
            print("✅ iOS构建环境检查通过")
            sys.exit(0)
        else:
            print("❌ iOS构建环境检查失败")
            sys.exit(1)
            
    # 环境检查
    if not builder.check_environment():
        print("❌ 构建环境检查失败，请先配置iOS开发环境")
        sys.exit(1)
        
    # 清理构建
    if args.clean:
        builder.clean_build()
        
    # 执行构建
    try:
        if args.device_type == "device":
            # 构建IPA
            success = builder.build_ipa(args.configuration, args.export_method)
            if success:
                output_dir = builder.organize_outputs(args.configuration)
                
                # 上传到TestFlight
                if args.upload_testflight:
                    ipa_files = list(output_dir.glob("*.ipa"))
                    if ipa_files:
                        builder.upload_to_testflight(ipa_files[0])
        else:
            # 构建模拟器版本
            success = builder.build_ios(args.configuration, "simulator")
            
        # 生成构建报告
        builder.generate_build_report()
        
        if success:
            print("\n🎉 iOS构建完成！")
            sys.exit(0)
        else:
            print("\n❌ iOS构建失败！")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n⚠️ 构建被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 构建过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 