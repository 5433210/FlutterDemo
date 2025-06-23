#!/usr/bin/env python3
"""
Windows平台构建脚本
支持MSIX打包、代码签名、Microsoft Store上传等
"""

import os
import sys
import subprocess
import argparse
import json
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path
from datetime import datetime

class WindowsBuilder:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.windows_dir = self.project_root / "windows"
        self.build_dir = self.project_root / "build" / "windows"
        self.output_dir = self.project_root / "releases" / "windows"
        
        # 确保输出目录存在
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def check_environment(self):
        """检查Windows构建环境"""
        print("🔍 检查Windows构建环境...")
        
        # 检查操作系统
        if sys.platform != "win32":
            print("❌ Windows构建需要在Windows系统上进行")
            return False
            
        # 检查Flutter
        try:
            # 在Windows上尝试不同的Flutter命令
            flutter_commands = ['flutter', 'flutter.bat', 'flutter.cmd']
            flutter_found = False
            for cmd in flutter_commands:
                try:
                    result = subprocess.run([cmd, '--version'], 
                                          capture_output=True, text=True, check=True, timeout=10,
                                          encoding='utf-8', errors='ignore')
                    if result.stdout and len(result.stdout.split()) > 1:
                        flutter_version = result.stdout.split()[1]
                        print(f"✅ Flutter: {flutter_version}")
                        flutter_found = True
                        break
                except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
                    continue
            
            if not flutter_found:
                print("❌ Flutter未安装或不在PATH中")
                return False
        except Exception as e:
            print(f"❌ Flutter检查失败: {e}")
            return False
            
        # 检查Visual Studio Build Tools
        msbuild_found = False
        
        # 首先尝试从PATH中查找
        try:
            result = subprocess.run(['where', 'msbuild'], 
                                  capture_output=True, text=True, check=True)
            print("✅ MSBuild可用 (PATH)")
            msbuild_found = True
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
            
        # 如果PATH中没有，尝试常见的Visual Studio安装路径
        if not msbuild_found:
            vs_paths = [
                Path("C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/MSBuild.exe"),
                Path("C:/Program Files/Microsoft Visual Studio/2022/Professional/MSBuild/Current/Bin/MSBuild.exe"),
                Path("C:/Program Files/Microsoft Visual Studio/2022/Enterprise/MSBuild/Current/Bin/MSBuild.exe"),
                Path("C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/MSBuild/Current/Bin/MSBuild.exe"),
                Path("C:/Program Files (x86)/Microsoft Visual Studio/2019/Professional/MSBuild/Current/Bin/MSBuild.exe"),
                Path("C:/Program Files (x86)/Microsoft Visual Studio/2019/Enterprise/MSBuild/Current/Bin/MSBuild.exe"),
            ]
            
            for msbuild_path in vs_paths:
                if msbuild_path.exists():
                    # 获取Visual Studio版本：C:/Program Files/Microsoft Visual Studio/2022/Community/...
                    vs_version = msbuild_path.parent.parent.parent.parent.parent.name  # 获取"2022"
                    vs_edition = msbuild_path.parent.parent.parent.parent.name  # 获取"Community"
                    print(f"✅ MSBuild可用 (Visual Studio {vs_version} {vs_edition})")
                    msbuild_found = True
                    break
                    
        if not msbuild_found:
            print("❌ Visual Studio Build Tools未安装")
            print("   请安装 Visual Studio 2019/2022 或 Visual Studio Build Tools")
            return False
            
        # 检查Windows SDK
        sdk_path = Path(os.environ.get('ProgramFiles(x86)', '')) / "Windows Kits" / "10"
        if sdk_path.exists():
            print("✅ Windows SDK可用")
        else:
            print("⚠️ Windows SDK路径未找到")
            
        # 检查签名工具
        signtool_found = False
        
        # 首先尝试从PATH中查找
        try:
            result = subprocess.run(['signtool'], 
                                  capture_output=True, text=True)
            print("✅ SignTool可用 (PATH)")
            signtool_found = True
        except FileNotFoundError:
            pass
            
        # 如果PATH中没有，尝试Windows SDK路径
        if not signtool_found:
            sdk_paths = [
                Path("C:/Program Files (x86)/Windows Kits/10/bin/10.0.22621.0/x64/signtool.exe"),
                Path("C:/Program Files (x86)/Windows Kits/10/bin/10.0.19041.0/x64/signtool.exe"),
                Path("C:/Program Files (x86)/Windows Kits/10/App Certification Kit/signtool.exe"),
            ]
            
            for signtool_path in sdk_paths:
                if signtool_path.exists():
                    print("✅ SignTool可用 (Windows SDK)")
                    signtool_found = True
                    break
                    
        if not signtool_found:
            print("⚠️ SignTool未找到（代码签名需要）")
            
        # 检查MSIX打包工具
        makeappx_found = False
        
        # 首先尝试从PATH中查找
        try:
            result = subprocess.run(['makeappx'], 
                                  capture_output=True, text=True)
            print("✅ MakeAppx可用 (PATH)")
            makeappx_found = True
        except FileNotFoundError:
            pass
            
        # 如果PATH中没有，尝试Windows SDK路径
        if not makeappx_found:
            sdk_paths = [
                Path("C:/Program Files (x86)/Windows Kits/10/bin/10.0.22621.0/x64/makeappx.exe"),
                Path("C:/Program Files (x86)/Windows Kits/10/bin/10.0.19041.0/x64/makeappx.exe"),
            ]
            
            for makeappx_path in sdk_paths:
                if makeappx_path.exists():
                    print("✅ MakeAppx可用 (Windows SDK)")
                    makeappx_found = True
                    break
                    
        if not makeappx_found:
            print("⚠️ MakeAppx未找到（MSIX打包需要）")
            
        return True
        
    def clean_build(self):
        """清理构建缓存"""
        print("🧹 清理构建缓存...")
        
        # Flutter clean
        subprocess.run(['flutter', 'clean'], cwd=self.project_root)
        
        # 删除构建目录
        if self.build_dir.exists():
            shutil.rmtree(self.build_dir)
            
        # 清理Windows特定的构建缓存
        windows_build_dirs = [
            self.windows_dir / "build",
            self.windows_dir / "runner" / "build"
        ]
        
        for build_dir in windows_build_dirs:
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
        """更新Windows版本信息"""
        print("📝 更新Windows版本信息...")
        
        version, build_number = self.get_version_info()
        
        # 更新Runner.rc文件
        rc_file = self.windows_dir / "runner" / "Runner.rc"
        if rc_file.exists():
            self.update_rc_version(rc_file, version, build_number)
            
        # 更新CMakeLists.txt
        cmake_file = self.windows_dir / "CMakeLists.txt"
        if cmake_file.exists():
            self.update_cmake_version(cmake_file, version, build_number)
            
        print(f"✅ 版本信息已更新 - 版本: {version}, 构建号: {build_number}")
        
    def update_rc_version(self, rc_file, version, build_number):
        """更新RC文件中的版本信息"""
        version_parts = version.split('.')
        while len(version_parts) < 4:
            version_parts.append('0')
            
        version_comma = ','.join(version_parts)
        version_string = '.'.join(version_parts)
        
        # 读取RC文件内容
        with open(rc_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # 替换版本信息
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if 'FILEVERSION' in line and not line.strip().startswith('//'):
                lines[i] = f'FILEVERSION {version_comma}'
            elif 'PRODUCTVERSION' in line and not line.strip().startswith('//'):
                lines[i] = f'PRODUCTVERSION {version_comma}'
            elif '"FileVersion"' in line:
                lines[i] = f'            VALUE "FileVersion", "{version_string}\\0"'
            elif '"ProductVersion"' in line:
                lines[i] = f'            VALUE "ProductVersion", "{version_string}\\0"'
                
        # 写回文件
        with open(rc_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
            
    def update_cmake_version(self, cmake_file, version, build_number):
        """更新CMakeLists.txt中的版本信息"""
        with open(cmake_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.strip().startswith('set(VERSION'):
                lines[i] = f'set(VERSION "{version}")'
            elif line.strip().startswith('set(BUILD_NUMBER'):
                lines[i] = f'set(BUILD_NUMBER "{build_number}")'
                
        with open(cmake_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
            
    def build_windows(self, build_mode="release"):
        """构建Windows应用"""
        print(f"🔨 构建Windows应用 - {build_mode} mode...")
        
        # 更新版本信息
        self.update_version_info()
        
        cmd = ['flutter', 'build', 'windows']
        
        # 构建模式
        if build_mode == "debug":
            cmd.append('--debug')
        elif build_mode == "profile":
            cmd.append('--profile')
        else:
            cmd.append('--release')
            
        # 执行构建
        try:
            result = subprocess.run(cmd, cwd=self.project_root, check=True)
            print("✅ Windows构建成功")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Windows构建失败: {e}")
            return False
            
    def create_msix_manifest(self):
        """创建MSIX清单文件"""
        print("📄 创建MSIX清单文件...")
        
        version, build_number = self.get_version_info()
        
        # MSIX版本格式必须是x.x.x.x
        version_parts = version.split('.')
        while len(version_parts) < 3:
            version_parts.append('0')
        msix_version = f"{version_parts[0]}.{version_parts[1]}.{version_parts[2]}.{build_number}"
        
        manifest_content = f'''<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities">
  <Identity Name="CharasGem"
            Publisher="CN=YourCompany"
            Version="{msix_version}" />
  
  <Properties>
    <DisplayName>CharasGem</DisplayName>
    <PublisherDisplayName>Your Company</PublisherDisplayName>
    <Logo>Assets\\StoreLogo.png</Logo>
    <Description>A versatile calligraphy management and practice application</Description>
  </Properties>
  
  <Dependencies>
    <TargetDeviceFamily Name="Windows.Universal" MinVersion="10.0.17763.0" MaxVersionTested="10.0.19041.0" />
    <PackageDependency Name="Microsoft.VCLibs.140.00" MinVersion="14.0.24217.0" Publisher="CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US" />
  </Dependencies>
  
  <Resources>
    <Resource Language="zh-CN" />
    <Resource Language="en-US" />
  </Resources>
  
  <Applications>
    <Application Id="CharasGem" Executable="demo.exe" EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements DisplayName="CharasGem"
                          Square150x150Logo="Assets\\Square150x150Logo.png"
                          Square44x44Logo="Assets\\Square44x44Logo.png"
                          Description="CharasGem - Calligraphy Practice App"
                          BackgroundColor="transparent">
        <uap:DefaultTile Wide310x150Logo="Assets\\Wide310x150Logo.png" />
        <uap:SplashScreen Image="Assets\\SplashScreen.png" />
      </uap:VisualElements>
      
      <Extensions>
        <uap:Extension Category="windows.fileTypeAssociation">
          <uap:FileTypeAssociation Name="copybook">
            <uap:SupportedFileTypes>
              <uap:FileType>.copybook</uap:FileType>
            </uap:SupportedFileTypes>
          </uap:FileTypeAssociation>
        </uap:Extension>
        
        <uap:Extension Category="windows.protocol">
          <uap:Protocol Name="charasgem">
            <uap:DisplayName>CharasGem Protocol</uap:DisplayName>
          </uap:Protocol>
        </uap:Extension>
      </Extensions>
    </Application>
  </Applications>
  
  <Capabilities>
    <Capability Name="internetClient" />
    <uap:Capability Name="documentsLibrary" />
    <uap:Capability Name="picturesLibrary" />
    <rescap:Capability Name="broadFileSystemAccess" />
  </Capabilities>
</Package>'''
        
        # 创建MSIX目录
        msix_dir = self.build_dir / "msix"
        msix_dir.mkdir(parents=True, exist_ok=True)
        
        # 写入清单文件
        manifest_file = msix_dir / "AppxManifest.xml"
        with open(manifest_file, 'w', encoding='utf-8') as f:
            f.write(manifest_content)
            
        print(f"✅ MSIX清单文件已创建: {manifest_file}")
        return manifest_file
        
    def create_msix_assets(self):
        """创建MSIX资源文件"""
        print("🎨 创建MSIX资源文件...")
        
        msix_dir = self.build_dir / "msix"
        assets_dir = msix_dir / "Assets"
        assets_dir.mkdir(exist_ok=True)
        
        # 这里应该复制实际的图标文件
        # 为了演示，我们创建占位符文件
        asset_files = [
            "StoreLogo.png",
            "Square150x150Logo.png", 
            "Square44x44Logo.png",
            "Wide310x150Logo.png",
            "SplashScreen.png"
        ]
        
        for asset_file in asset_files:
            asset_path = assets_dir / asset_file
            if not asset_path.exists():
                # 创建占位符文件（实际应用中应该使用真实图标）
                asset_path.write_text(f"# Placeholder for {asset_file}")
                
        print("✅ MSIX资源文件已准备")
        
    def build_msix(self, build_mode="release"):
        """构建MSIX包"""
        print("📦 构建MSIX包...")
        
        # 先构建Windows应用
        if not self.build_windows(build_mode):
            return False
            
        # 创建MSIX清单和资源
        manifest_file = self.create_msix_manifest()
        self.create_msix_assets()
        
        # 复制构建产物到MSIX目录
        msix_dir = self.build_dir / "msix"
        windows_build_dir = self.project_root / "build" / "windows" / "runner" / "Release"
        
        if not windows_build_dir.exists():
            print("❌ Windows构建产物不存在")
            return False
            
        # 复制可执行文件和依赖
        for item in windows_build_dir.iterdir():
            if item.is_file():
                shutil.copy2(item, msix_dir / item.name)
            elif item.is_dir() and item.name in ["data"]:
                shutil.copytree(item, msix_dir / item.name, dirs_exist_ok=True)
                
        # 使用MakeAppx创建MSIX包
        version, build_number = self.get_version_info()
        msix_file = self.output_dir / f"CharasGem-v{version}-{build_number}.msix"
        
        try:
            cmd = [
                'makeappx', 'pack',
                '/d', str(msix_dir),
                '/p', str(msix_file),
                '/o'  # 覆盖现有文件
            ]
            
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print("✅ MSIX包创建成功")
            return msix_file
            
        except subprocess.CalledProcessError as e:
            print(f"❌ MSIX包创建失败: {e}")
            print(f"错误输出: {e.stderr}")
            return None
            
    def sign_msix(self, msix_file, cert_file=None, cert_password=None):
        """签名MSIX包"""
        print("🔐 签名MSIX包...")
        
        if not cert_file:
            cert_file = os.environ.get('WINDOWS_CERT_FILE')
        if not cert_password:
            cert_password = os.environ.get('WINDOWS_CERT_PASSWORD')
            
        if not cert_file or not Path(cert_file).exists():
            print("⚠️ 证书文件未找到，跳过签名")
            return True
            
        try:
            cmd = [
                'signtool', 'sign',
                '/f', cert_file,
                '/fd', 'SHA256',
                '/t', 'http://timestamp.digicert.com'
            ]
            
            if cert_password:
                cmd.extend(['/p', cert_password])
                
            cmd.append(str(msix_file))
            
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print("✅ MSIX包签名成功")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ MSIX包签名失败: {e}")
            print(f"错误输出: {e.stderr}")
            return False
            
    def organize_outputs(self, build_mode="release"):
        """整理构建产物"""
        print("📦 整理构建产物...")
        
        version, build_number = self.get_version_info()
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 目标目录
        target_dir = self.output_dir / f"v{version}_build{build_number}_{timestamp}"
        target_dir.mkdir(parents=True, exist_ok=True)
        
        # 复制MSIX文件
        msix_files = list(self.output_dir.glob("*.msix"))
        for msix_file in msix_files:
            if msix_file.parent == self.output_dir:  # 只复制根目录下的MSIX文件
                target_msix = target_dir / msix_file.name
                shutil.copy2(msix_file, target_msix)
                print(f"📄 MSIX: {target_msix}")
                msix_file.unlink()  # 删除原文件
                
        # 复制可执行文件
        exe_source_dir = self.project_root / "build" / "windows" / "runner" / "Release"
        if exe_source_dir.exists():
            exe_target_dir = target_dir / "exe"
            shutil.copytree(exe_source_dir, exe_target_dir)
            print(f"📁 EXE: {exe_target_dir}")
            
        # 生成构建信息
        build_info = {
            "platform": "Windows",
            "version": version,
            "build_number": build_number,
            "build_mode": build_mode,
            "timestamp": timestamp,
            "files": [f.name for f in target_dir.iterdir()]
        }
        
        with open(target_dir / "build_info.json", "w", encoding="utf-8") as f:
            json.dump(build_info, f, indent=2, ensure_ascii=False)
            
        print(f"✅ 构建产物已整理到: {target_dir}")
        return target_dir
        
    def generate_build_report(self):
        """生成构建报告"""
        print("📋 生成构建报告...")
        
        report = {
            "platform": "Windows",
            "timestamp": datetime.now().isoformat(),
            "environment": {
                "windows_version": self.get_windows_version(),
                "visual_studio_version": self.get_vs_version(),
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
        
    def get_windows_version(self):
        """获取Windows版本"""
        try:
            result = subprocess.run(['ver'], shell=True, 
                                  capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except:
            return "Unknown"
            
    def get_vs_version(self):
        """获取Visual Studio版本"""
        try:
            result = subprocess.run(['msbuild', '/version'], 
                                  capture_output=True, text=True, check=True)
            lines = result.stdout.strip().split('\n')
            return lines[-1] if lines else "Unknown"
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
    parser = argparse.ArgumentParser(description="Windows平台构建脚本")
    parser.add_argument("--build-mode", choices=["debug", "profile", "release"], 
                       default="release", help="构建模式")
    parser.add_argument("--output-format", choices=["exe", "msix", "both"], 
                       default="both", help="输出格式")
    parser.add_argument("--cert-file", help="代码签名证书文件路径")
    parser.add_argument("--cert-password", help="证书密码")
    parser.add_argument("--clean", action="store_true", 
                       help="构建前清理缓存")
    parser.add_argument("--check-env", action="store_true", 
                       help="仅检查构建环境")
    
    args = parser.parse_args()
    
    builder = WindowsBuilder()
    
    # 检查环境
    if args.check_env:
        if builder.check_environment():
            print("✅ Windows构建环境检查通过")
            sys.exit(0)
        else:
            print("❌ Windows构建环境检查失败")
            sys.exit(1)
            
    # 环境检查
    if not builder.check_environment():
        print("❌ 构建环境检查失败，请先配置Windows开发环境")
        sys.exit(1)
        
    # 清理构建
    if args.clean:
        builder.clean_build()
        
    # 执行构建
    try:
        success = True
        
        if args.output_format in ["exe", "both"]:
            # 构建EXE
            if not builder.build_windows(args.build_mode):
                success = False
                
        if args.output_format in ["msix", "both"]:
            # 构建MSIX
            msix_file = builder.build_msix(args.build_mode)
            if msix_file:
                # 签名MSIX
                builder.sign_msix(msix_file, args.cert_file, args.cert_password)
            else:
                success = False
                
        if success:
            builder.organize_outputs(args.build_mode)
            
        # 生成构建报告
        builder.generate_build_report()
        
        if success:
            print("\n🎉 Windows构建完成！")
            sys.exit(0)
        else:
            print("\n❌ Windows构建失败！")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n⚠️ 构建被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 构建过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 