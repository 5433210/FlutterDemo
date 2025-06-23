#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Android平台构建脚本
支持APK/AAB构建、多渠道打包、签名配置等
"""

import os
import sys
import subprocess
import argparse
import json
import shutil
from pathlib import Path
from datetime import datetime

class AndroidBuilder:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.android_dir = self.project_root / "android"
        self.build_dir = self.project_root / "build" / "android"
        self.output_dir = self.project_root / "releases" / "android"
        
        # 确保输出目录存在
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def check_environment(self):
        """检查Android构建环境"""
        print("🔍 检查Android构建环境...")
        
        # 检查Flutter - 修复编码问题
        flutter_found = False
        
        try:
            # 尝试多种方式调用flutter命令
            flutter_commands = [
                ['flutter', '--version'],
                ['flutter.bat', '--version']
            ]
            
            for cmd in flutter_commands:
                try:
                    result = subprocess.run(cmd, 
                                          capture_output=True, text=True, timeout=10,
                                          encoding='utf-8', errors='ignore')
                    if result.returncode == 0 and 'Flutter' in result.stdout:
                        lines = result.stdout.split('\n')
                        for line in lines:
                            if 'Flutter' in line and '•' in line:
                                # 提取版本信息
                                parts = line.split('•')
                                if len(parts) >= 2:
                                    version = parts[0].replace('Flutter', '').strip()
                                    print(f"✅ Flutter: {version}")
                                    flutter_found = True
                                    break
                        
                        if not flutter_found and 'Flutter' in result.stdout:
                            print("✅ Flutter: 已安装")
                            flutter_found = True
                        
                        if flutter_found:
                            break
                except:
                    continue
            
            # 如果还没找到，尝试shell方式
            if not flutter_found:
                result = subprocess.run('flutter --version', 
                                      capture_output=True, text=True, timeout=10,
                                      encoding='utf-8', errors='ignore', shell=True)
                if result.returncode == 0 and 'Flutter' in result.stdout:
                    lines = result.stdout.split('\n')
                    for line in lines:
                        if 'Flutter' in line:
                            print(f"✅ Flutter: {line.strip()}")
                            flutter_found = True
                            break
                        
        except Exception as e:
            print(f"Flutter检测异常: {e}")
        
        if not flutter_found:
            print("⚠️ Flutter命令检测失败，但可能仍可构建")
            print("请确保Flutter在PATH中或手动运行构建命令")
            
        # 检查Android SDK - 自动检测
        android_home = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
        
        # 如果环境变量没设置，尝试常见路径
        if not android_home:
            username = os.environ.get('USERNAME', os.environ.get('USER', ''))
            potential_paths = [
                Path.home() / "AppData" / "Local" / "Android" / "Sdk",
                Path("C:/Android/Sdk"),
                Path(f"C:/Users/{username}/AppData/Local/Android/Sdk"),
            ]
            
            for path in potential_paths:
                if path.exists() and (path / "platform-tools").exists():
                    android_home = str(path)
                    print(f"✅ Android SDK: {android_home} (自动检测)")
                    break
        else:
            print(f"✅ Android SDK: {android_home}")
        
        if not android_home:
            print("❌ Android SDK未找到")
            print("请安装Android SDK或设置ANDROID_HOME环境变量")
            return False
            
        # 检查Android SDK组件
        sdk_path = Path(android_home)
        platform_tools = sdk_path / "platform-tools"
        build_tools = sdk_path / "build-tools"
        platforms = sdk_path / "platforms"
        
        if not platform_tools.exists():
            print("❌ Android platform-tools未找到")
            return False
        print(f"✅ Platform Tools: {platform_tools}")
        
        if not build_tools.exists() or not any(build_tools.iterdir()):
            print("❌ Android build-tools未找到")
            return False
        
        # 找到最新的build-tools版本
        build_tools_versions = [d.name for d in build_tools.iterdir() if d.is_dir()]
        if build_tools_versions:
            latest_build_tools = sorted(build_tools_versions)[-1]
            print(f"✅ Build Tools: {latest_build_tools}")
        
        if not platforms.exists() or not any(platforms.iterdir()):
            print("❌ Android platforms未找到")
            return False
            
        # 找到可用的平台版本
        platform_versions = [d.name for d in platforms.iterdir() if d.is_dir()]
        if platform_versions:
            latest_platform = sorted(platform_versions)[-1]
            print(f"✅ Android Platforms: {latest_platform}")
            
        # 检查Java - 使用编码修复
        try:
            result = subprocess.run(['java', '-version'], 
                                  capture_output=True, text=True, timeout=5,
                                  encoding='utf-8', errors='ignore')
            if result.returncode == 0:
                # Java版本信息通常在stderr中
                java_output = result.stderr if result.stderr else result.stdout
                java_lines = java_output.split('\n')
                if java_lines:
                    java_version = java_lines[0].strip()
                    print(f"✅ Java: {java_version}")
                else:
                    print("✅ Java: 已安装")
            else:
                print("⚠️ Java未在PATH中，但Flutter可能使用内嵌JDK")
        except Exception as e:
            print("⚠️ Java未在PATH中，但Flutter可能使用内嵌JDK")
            
        # 检查Gradle - 通过Flutter项目检查
        try:
            if (self.android_dir / "gradlew").exists() or (self.android_dir / "gradlew.bat").exists():
                gradlew_cmd = "gradlew.bat" if os.name == 'nt' else "./gradlew"
                result = subprocess.run([gradlew_cmd, '--version'], 
                                      cwd=self.android_dir, capture_output=True, text=True, timeout=30,
                                      encoding='utf-8', errors='ignore', shell=True)
                if result.returncode == 0:
                    gradle_lines = [line for line in result.stdout.split('\n') if 'Gradle' in line]
                    if gradle_lines:
                        print(f"✅ {gradle_lines[0]}")
                    else:
                        print("✅ Gradle Wrapper可用")
                else:
                    print("⚠️ Gradle检查失败，但可能仍能构建")
            else:
                print("⚠️ Gradle Wrapper未找到")
        except Exception as e:
            print("⚠️ Gradle检查失败，但可能仍能构建")
            
        print("✅ Android构建环境检查通过")
        return True
        
    def clean_build(self):
        """清理构建缓存"""
        print("🧹 清理构建缓存...")
        
        try:
            # Flutter clean
            subprocess.run(['flutter', 'clean'], cwd=self.project_root, check=True)
        except subprocess.CalledProcessError as e:
            print(f"⚠️ Flutter clean失败: {e}")
        
        try:
            # Gradle clean
            gradlew_cmd = "gradlew.bat" if os.name == 'nt' else "./gradlew"
            subprocess.run([gradlew_cmd, 'clean'], cwd=self.android_dir, check=True, shell=True)
        except subprocess.CalledProcessError as e:
            print(f"⚠️ Gradle clean失败: {e}")
        
        # 删除构建目录
        if self.build_dir.exists():
            try:
                shutil.rmtree(self.build_dir)
            except Exception as e:
                print(f"⚠️ 删除构建目录失败: {e}")
            
        print("✅ 构建缓存已清理")
        
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
            
    def build_apk(self, flavor="", build_type="release", split_per_abi=False):
        """构建APK"""
        print(f"🔨 构建APK - {flavor}{build_type}...")
        
        cmd = ['flutter', 'build', 'apk']
        
        # 构建类型
        if build_type == "debug":
            cmd.append('--debug')
        elif build_type == "profile":
            cmd.append('--profile')
        else:
            cmd.append('--release')
            
        # 多渠道
        if flavor:
            cmd.extend(['--flavor', flavor])
            
        # 分ABI构建
        if split_per_abi:
            cmd.append('--split-per-abi')
            
        # 执行构建 - 优先使用shell方式
        try:
            # 在Windows上使用shell方式更可靠
            cmd_str = ' '.join(cmd)
            result = subprocess.run(cmd_str, cwd=self.project_root, check=True,
                                  encoding='utf-8', errors='ignore', shell=True)
            print("✅ APK构建成功")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ APK构建失败: {e}")
            return False
        except FileNotFoundError:
            print("❌ Flutter命令未找到，请确保Flutter已正确安装并在PATH中")
            return False
            
    def build_aab(self, flavor="", build_type="release"):
        """构建AAB (Android App Bundle)"""
        print(f"🔨 构建AAB - {flavor}{build_type}...")
        
        cmd = ['flutter', 'build', 'appbundle']
        
        # 构建类型
        if build_type == "debug":
            cmd.append('--debug')
        elif build_type == "profile":
            cmd.append('--profile')
        else:
            cmd.append('--release')
            
        # 多渠道
        if flavor:
            cmd.extend(['--flavor', flavor])
            
        # 执行构建 - 优先使用shell方式
        try:
            # 在Windows上使用shell方式更可靠
            cmd_str = ' '.join(cmd)
            result = subprocess.run(cmd_str, cwd=self.project_root, check=True,
                                  encoding='utf-8', errors='ignore', shell=True)
            print("✅ AAB构建成功")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ AAB构建失败: {e}")
            return False
        except FileNotFoundError:
            print("❌ Flutter命令未找到，请确保Flutter已正确安装并在PATH中")
            return False
            
    def organize_outputs(self, flavor="", build_type="release"):
        """整理构建产物"""
        print("📦 整理构建产物...")
        
        version, build_number = self.get_version_info()
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 构建产物源目录
        if flavor:
            source_dir = self.project_root / "build" / "app" / "outputs" / "flutter-apk"
            aab_source_dir = self.project_root / "build" / "app" / "outputs" / "bundle" / f"{flavor}Release"
        else:
            source_dir = self.project_root / "build" / "app" / "outputs" / "flutter-apk"
            aab_source_dir = self.project_root / "build" / "app" / "outputs" / "bundle" / "release"
            
        # 目标目录
        target_dir = self.output_dir / f"v{version}_build{build_number}_{timestamp}"
        target_dir.mkdir(parents=True, exist_ok=True)
        
        # 复制APK文件
        apk_files = list(source_dir.glob("*.apk"))
        for apk_file in apk_files:
            target_apk = target_dir / apk_file.name
            shutil.copy2(apk_file, target_apk)
            print(f"📄 APK: {target_apk}")
            
        # 复制AAB文件
        if aab_source_dir.exists():
            aab_files = list(aab_source_dir.glob("*.aab"))
            for aab_file in aab_files:
                target_aab = target_dir / aab_file.name
                shutil.copy2(aab_file, target_aab)
                print(f"📄 AAB: {target_aab}")
                
        # 生成构建信息
        build_info = {
            "version": version,
            "build_number": build_number,
            "flavor": flavor,
            "build_type": build_type,
            "timestamp": timestamp,
            "files": [f.name for f in target_dir.iterdir() if f.is_file()]
        }
        
        with open(target_dir / "build_info.json", "w", encoding="utf-8") as f:
            json.dump(build_info, f, indent=2, ensure_ascii=False)
            
        print(f"✅ 构建产物已整理到: {target_dir}")
        return target_dir
        
    def build_all_flavors(self, build_type="release", output_format="both"):
        """构建所有渠道"""
        flavors = ["googleplay", "huawei", "xiaomi", "direct"]
        success_count = 0
        
        for flavor in flavors:
            print(f"\n🚀 开始构建 {flavor} 渠道...")
            
            success = True
            
            # 构建APK
            if output_format in ["apk", "both"]:
                if not self.build_apk(flavor, build_type):
                    success = False
                    
            # 构建AAB
            if output_format in ["aab", "both"]:
                if not self.build_aab(flavor, build_type):
                    success = False
                    
            if success:
                self.organize_outputs(flavor, build_type)
                success_count += 1
                print(f"✅ {flavor} 渠道构建成功")
            else:
                print(f"❌ {flavor} 渠道构建失败")
                
        print(f"\n📊 构建结果: {success_count}/{len(flavors)} 个渠道成功")
        return success_count == len(flavors)
        
    def generate_build_report(self):
        """生成构建报告"""
        print("📋 生成构建报告...")
        
        report = {
            "platform": "Android",
            "timestamp": datetime.now().isoformat(),
            "environment": {
                "android_home": os.environ.get('ANDROID_HOME', 'Not set'),
                "java_home": os.environ.get('JAVA_HOME', 'Not set')
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

def main():
    parser = argparse.ArgumentParser(description="Android平台构建脚本")
    parser.add_argument("--flavor", choices=["googleplay", "huawei", "xiaomi", "direct"], 
                       help="构建渠道")
    parser.add_argument("--build-type", choices=["debug", "profile", "release"], 
                       default="release", help="构建类型")
    parser.add_argument("--format", choices=["apk", "aab", "both"], 
                       default="both", help="输出格式")
    parser.add_argument("--all-flavors", action="store_true", 
                       help="构建所有渠道")
    parser.add_argument("--clean", action="store_true", 
                       help="构建前清理缓存")
    parser.add_argument("--check-env", action="store_true", 
                       help="仅检查构建环境")
    
    args = parser.parse_args()
    
    builder = AndroidBuilder()
    
    # 检查环境
    if args.check_env:
        if builder.check_environment():
            print("✅ Android构建环境检查通过")
            sys.exit(0)
        else:
            print("❌ Android构建环境检查失败")
            sys.exit(1)
            
    # 环境检查
    if not builder.check_environment():
        print("❌ 构建环境检查失败，请先配置Android开发环境")
        sys.exit(1)
        
    # 清理构建
    if args.clean:
        builder.clean_build()
        
    # 执行构建
    try:
        if args.all_flavors:
            # 构建所有渠道
            success = builder.build_all_flavors(args.build_type, args.format)
        else:
            # 构建单个渠道
            success = True
            flavor = args.flavor or ""
            
            if args.format in ["apk", "both"]:
                if not builder.build_apk(flavor, args.build_type):
                    success = False
                    
            if args.format in ["aab", "both"]:
                if not builder.build_aab(flavor, args.build_type):
                    success = False
                    
            if success:
                builder.organize_outputs(flavor, args.build_type)
                
        # 生成构建报告
        builder.generate_build_report()
        
        if success:
            print("\n🎉 Android构建完成！")
            sys.exit(0)
        else:
            print("\n❌ Android构建失败！")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n⚠️ 构建被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 构建过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 