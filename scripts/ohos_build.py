#!/usr/bin/env python3
"""
鸿蒙OS平台构建脚本
支持HAP构建、签名、AppGallery上传等
"""

import os
import sys
import subprocess
import argparse
import json
import shutil
import json5
from pathlib import Path
from datetime import datetime

class HarmonyOSBuilder:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.ohos_dir = self.project_root / "ohos"
        self.build_dir = self.project_root / "build" / "ohos"
        self.output_dir = self.project_root / "releases" / "ohos"
        
        # 确保输出目录存在
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def check_environment(self):
        """检查鸿蒙OS构建环境"""
        print("🔍 检查鸿蒙OS构建环境...")
        
        # 检查DevEco Studio命令行工具
        deveco_paths = [
            Path.home() / "Huawei" / "DevEco Studio" / "tools" / "hvigor",
            Path("/Applications/DevEco-Studio.app/Contents/tools/hvigor"),  # macOS
            Path("C:/Users") / os.environ.get('USERNAME', '') / "AppData/Local/Huawei/DevEco Studio/tools/hvigor"  # Windows
        ]
        
        hvigor_found = False
        for path in deveco_paths:
            if path.exists():
                print(f"✅ DevEco Studio工具链: {path}")
                hvigor_found = True
                break
                
        if not hvigor_found:
            print("❌ DevEco Studio工具链未找到")
            return False
            
        # 检查Node.js
        try:
            result = subprocess.run(['node', '--version'], 
                                  capture_output=True, text=True, check=True)
            node_version = result.stdout.strip()
            print(f"✅ Node.js: {node_version}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("❌ Node.js未安装")
            return False
            
        # 检查npm
        try:
            result = subprocess.run(['npm', '--version'], 
                                  capture_output=True, text=True, check=True)
            npm_version = result.stdout.strip()
            print(f"✅ npm: {npm_version}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("❌ npm未安装")
            return False
            
        # 检查HarmonyOS SDK
        sdk_path = os.environ.get('HARMONYOS_SDK_HOME') or os.environ.get('OHOS_SDK_HOME')
        if sdk_path and Path(sdk_path).exists():
            print(f"✅ HarmonyOS SDK: {sdk_path}")
        else:
            print("⚠️ HarmonyOS SDK路径未配置")
            
        return True
        
    def clean_build(self):
        """清理构建缓存"""
        print("🧹 清理构建缓存...")
        
        # 删除构建目录
        if self.build_dir.exists():
            shutil.rmtree(self.build_dir)
            
        # 清理鸿蒙项目构建缓存
        ohos_build_dirs = [
            self.ohos_dir / "build",
            self.ohos_dir / "entry" / "build",
            self.ohos_dir / "node_modules"
        ]
        
        for build_dir in ohos_build_dirs:
            if build_dir.exists():
                shutil.rmtree(build_dir)
                
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
            
    def update_version_info(self):
        """更新鸿蒙OS版本信息"""
        print("📝 更新鸿蒙OS版本信息...")
        
        version, build_number = self.get_version_info()
        
        # 更新app.json5
        app_config_file = self.ohos_dir / "app" / "app.json5"
        if app_config_file.exists():
            self.update_app_config(app_config_file, version, build_number)
            
        # 更新entry模块配置
        entry_config_file = self.ohos_dir / "entry" / "src" / "main" / "config.json"
        if entry_config_file.exists():
            self.update_entry_config(entry_config_file, version, build_number)
            
        print(f"✅ 版本信息已更新 - 版本: {version}, 构建号: {build_number}")
        
    def update_app_config(self, config_file, version, build_number):
        """更新应用级配置"""
        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                config = json5.load(f)
                
            # 更新版本信息
            if 'app' not in config:
                config['app'] = {}
                
            config['app']['versionName'] = version
            config['app']['versionCode'] = int(build_number)
            
            with open(config_file, 'w', encoding='utf-8') as f:
                json5.dump(config, f, indent=2, ensure_ascii=False)
                
        except Exception as e:
            print(f"⚠️ 更新app.json5失败: {e}")
            
    def update_entry_config(self, config_file, version, build_number):
        """更新entry模块配置"""
        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                config = json.load(f)
                
            # 更新版本信息
            if 'app' not in config:
                config['app'] = {}
                
            config['app']['version'] = {
                "name": version,
                "code": int(build_number)
            }
            
            with open(config_file, 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2, ensure_ascii=False)
                
        except Exception as e:
            print(f"⚠️ 更新entry配置失败: {e}")
            
    def install_dependencies(self):
        """安装依赖"""
        print("📦 安装鸿蒙OS项目依赖...")
        
        try:
            # 安装npm依赖
            result = subprocess.run(['npm', 'install'], 
                                  cwd=self.ohos_dir, check=True)
            print("✅ npm依赖安装成功")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ npm依赖安装失败: {e}")
            return False
            
    def build_hap(self, build_mode="release", target_platform="default"):
        """构建HAP包"""
        print(f"🔨 构建HAP包 - {build_mode} mode for {target_platform}...")
        
        # 更新版本信息
        self.update_version_info()
        
        # 安装依赖
        if not self.install_dependencies():
            return False
            
        # 构建命令
        if build_mode == "debug":
            cmd = ['npm', 'run', 'build:debug']
        else:
            cmd = ['npm', 'run', 'build:release']
            
        # 执行构建
        try:
            result = subprocess.run(cmd, cwd=self.ohos_dir, check=True)
            print("✅ HAP构建成功")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ HAP构建失败: {e}")
            return False
            
    def sign_hap(self, hap_path, keystore_path=None, keystore_password=None):
        """签名HAP包"""
        print("🔐 签名HAP包...")
        
        if not keystore_path:
            keystore_path = os.environ.get('OHOS_KEYSTORE_FILE')
        if not keystore_password:
            keystore_password = os.environ.get('OHOS_KEYSTORE_PASSWORD')
            
        if not keystore_path or not Path(keystore_path).exists():
            print("⚠️ 签名密钥库未配置，跳过签名")
            return True
            
        try:
            # 使用hvigor工具签名
            cmd = [
                'hvigor', 'sign',
                '--keystore', keystore_path,
                '--keystore-password', keystore_password or '',
                '--hap', str(hap_path)
            ]
            
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print("✅ HAP签名成功")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ HAP签名失败: {e}")
            return False
        except FileNotFoundError:
            print("⚠️ hvigor工具未找到，跳过签名")
            return True
            
    def create_app_package(self, build_mode="release"):
        """创建应用包"""
        print("📦 创建应用包...")
        
        version, build_number = self.get_version_info()
        
        # 查找构建产物
        build_output_dir = self.ohos_dir / "entry" / "build" / "default" / "outputs" / "default"
        if not build_output_dir.exists():
            print("❌ 构建产物目录不存在")
            return None
            
        # 查找HAP文件
        hap_files = list(build_output_dir.glob("*.hap"))
        if not hap_files:
            print("❌ 未找到HAP文件")
            return None
            
        hap_file = hap_files[0]
        
        # 创建应用包目录
        package_dir = self.build_dir / "package"
        package_dir.mkdir(parents=True, exist_ok=True)
        
        # 复制HAP文件
        target_hap_name = f"CharasGem-v{version}-{build_number}.hap"
        target_hap = package_dir / target_hap_name
        shutil.copy2(hap_file, target_hap)
        
        # 签名HAP
        self.sign_hap(target_hap)
        
        print(f"✅ 应用包创建成功: {target_hap}")
        return target_hap
        
    def organize_outputs(self, build_mode="release"):
        """整理构建产物"""
        print("📦 整理构建产物...")
        
        version, build_number = self.get_version_info()
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 目标目录
        target_dir = self.output_dir / f"v{version}_build{build_number}_{timestamp}"
        target_dir.mkdir(parents=True, exist_ok=True)
        
        # 复制HAP文件
        package_dir = self.build_dir / "package"
        if package_dir.exists():
            hap_files = list(package_dir.glob("*.hap"))
            for hap_file in hap_files:
                target_hap = target_dir / hap_file.name
                shutil.copy2(hap_file, target_hap)
                print(f"📱 HAP: {target_hap}")
                
        # 复制原始构建产物
        build_output_dir = self.ohos_dir / "entry" / "build"
        if build_output_dir.exists():
            target_build_dir = target_dir / "build"
            shutil.copytree(build_output_dir, target_build_dir, dirs_exist_ok=True)
            print(f"📁 Build: {target_build_dir}")
            
        # 生成构建信息
        build_info = {
            "platform": "HarmonyOS",
            "version": version,
            "build_number": build_number,
            "build_mode": build_mode,
            "timestamp": timestamp,
            "files": [f.name for f in target_dir.iterdir() if f.is_file()],
            "sdk_version": self.get_sdk_version()
        }
        
        with open(target_dir / "build_info.json", "w", encoding="utf-8") as f:
            json.dump(build_info, f, indent=2, ensure_ascii=False)
            
        print(f"✅ 构建产物已整理到: {target_dir}")
        return target_dir
        
    def upload_to_appgallery(self, hap_path):
        """上传到AppGallery"""
        print("🚀 上传到AppGallery...")
        
        # 检查AppGallery Connect配置
        client_id = os.environ.get('APPGALLERY_CLIENT_ID')
        client_secret = os.environ.get('APPGALLERY_CLIENT_SECRET')
        app_id = os.environ.get('APPGALLERY_APP_ID')
        
        if not all([client_id, client_secret, app_id]):
            print("⚠️ AppGallery Connect配置不完整，跳过上传")
            return False
            
        # 这里应该实现AppGallery Connect API调用
        # 由于API较为复杂，这里只做占位实现
        print("📋 AppGallery Connect API上传功能需要具体实现")
        print("💡 提示: 可以使用AppGallery Connect CLI工具进行上传")
        
        return True
        
    def run_tests(self):
        """运行测试"""
        print("🧪 运行鸿蒙OS测试...")
        
        try:
            cmd = ['npm', 'run', 'test']
            result = subprocess.run(cmd, cwd=self.ohos_dir, check=True)
            print("✅ 测试通过")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ 测试失败: {e}")
            return False
        except FileNotFoundError:
            print("⚠️ 测试脚本未配置")
            return True
            
    def generate_build_report(self):
        """生成构建报告"""
        print("📋 生成构建报告...")
        
        report = {
            "platform": "HarmonyOS",
            "timestamp": datetime.now().isoformat(),
            "environment": {
                "sdk_version": self.get_sdk_version(),
                "node_version": self.get_node_version(),
                "npm_version": self.get_npm_version()
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
        
    def get_sdk_version(self):
        """获取HarmonyOS SDK版本"""
        sdk_path = os.environ.get('HARMONYOS_SDK_HOME') or os.environ.get('OHOS_SDK_HOME')
        if sdk_path:
            version_file = Path(sdk_path) / "version.txt"
            if version_file.exists():
                return version_file.read_text().strip()
        return "Unknown"
        
    def get_node_version(self):
        """获取Node.js版本"""
        try:
            result = subprocess.run(['node', '--version'], 
                                  capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except:
            return "Unknown"
            
    def get_npm_version(self):
        """获取npm版本"""
        try:
            result = subprocess.run(['npm', '--version'], 
                                  capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except:
            return "Unknown"

def main():
    parser = argparse.ArgumentParser(description="鸿蒙OS平台构建脚本")
    parser.add_argument("--build-mode", choices=["debug", "release"], 
                       default="release", help="构建模式")
    parser.add_argument("--target-platform", choices=["default", "phone", "tablet", "tv", "watch"], 
                       default="default", help="目标平台")
    parser.add_argument("--keystore-path", help="签名密钥库路径")
    parser.add_argument("--keystore-password", help="密钥库密码")
    parser.add_argument("--upload-appgallery", action="store_true", 
                       help="上传到AppGallery")
    parser.add_argument("--run-tests", action="store_true", 
                       help="运行测试")
    parser.add_argument("--clean", action="store_true", 
                       help="构建前清理缓存")
    parser.add_argument("--check-env", action="store_true", 
                       help="仅检查构建环境")
    
    args = parser.parse_args()
    
    builder = HarmonyOSBuilder()
    
    # 检查环境
    if args.check_env:
        if builder.check_environment():
            print("✅ 鸿蒙OS构建环境检查通过")
            sys.exit(0)
        else:
            print("❌ 鸿蒙OS构建环境检查失败")
            sys.exit(1)
            
    # 环境检查
    if not builder.check_environment():
        print("❌ 构建环境检查失败，请先配置鸿蒙OS开发环境")
        sys.exit(1)
        
    # 清理构建
    if args.clean:
        builder.clean_build()
        
    # 执行构建
    try:
        success = True
        
        # 运行测试
        if args.run_tests:
            if not builder.run_tests():
                success = False
                
        # 构建HAP
        if success:
            success = builder.build_hap(args.build_mode, args.target_platform)
            
        if success:
            # 创建应用包
            hap_path = builder.create_app_package(args.build_mode)
            
            if hap_path:
                # 整理输出
                builder.organize_outputs(args.build_mode)
                
                # 上传到AppGallery
                if args.upload_appgallery:
                    builder.upload_to_appgallery(hap_path)
            else:
                success = False
                
        # 生成构建报告
        builder.generate_build_report()
        
        if success:
            print("\n🎉 鸿蒙OS构建完成！")
            sys.exit(0)
        else:
            print("\n❌ 鸿蒙OS构建失败！")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n⚠️ 构建被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 构建过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 