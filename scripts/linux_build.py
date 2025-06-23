#!/usr/bin/env python3
"""
Linux平台构建脚本
支持多种打包格式（AppImage、Snap、Flatpak、DEB、RPM）
"""

import os
import sys
import subprocess
import argparse
import json
import shutil
import tempfile
from pathlib import Path
from datetime import datetime

class LinuxBuilder:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.linux_dir = self.project_root / "linux"
        self.build_dir = self.project_root / "build" / "linux"
        self.output_dir = self.project_root / "releases" / "linux"
        
        # 确保输出目录存在
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def check_environment(self):
        """检查Linux构建环境"""
        print("🔍 检查Linux构建环境...")
        
        # 检查操作系统
        if sys.platform != "linux":
            print("❌ Linux构建需要在Linux系统上进行")
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
            
        # 检查构建工具
        build_tools = {
            'cmake': 'CMake',
            'ninja': 'Ninja',
            'pkg-config': 'pkg-config',
            'gcc': 'GCC',
            'g++': 'G++'
        }
        
        for tool, name in build_tools.items():
            try:
                subprocess.run([tool, '--version'], 
                             capture_output=True, text=True, check=True)
                print(f"✅ {name}可用")
            except (subprocess.CalledProcessError, FileNotFoundError):
                print(f"❌ {name}未安装")
                return False
                
        # 检查GTK开发库
        try:
            subprocess.run(['pkg-config', '--exists', 'gtk+-3.0'], check=True)
            print("✅ GTK+3开发库可用")
        except subprocess.CalledProcessError:
            print("❌ GTK+3开发库未安装")
            return False
            
        # 检查打包工具（可选）
        optional_tools = {
            'appimagetool': 'AppImage工具',
            'snapcraft': 'Snap工具',
            'flatpak-builder': 'Flatpak工具',
            'dpkg-deb': 'DEB打包工具',
            'rpmbuild': 'RPM打包工具'
        }
        
        for tool, name in optional_tools.items():
            try:
                subprocess.run([tool, '--version'], 
                             capture_output=True, text=True, check=True)
                print(f"✅ {name}可用")
            except (subprocess.CalledProcessError, FileNotFoundError):
                print(f"⚠️ {name}未安装（可选）")
                
        return True
        
    def clean_build(self):
        """清理构建缓存"""
        print("🧹 清理构建缓存...")
        
        # Flutter clean
        subprocess.run(['flutter', 'clean'], cwd=self.project_root)
        
        # 删除构建目录
        if self.build_dir.exists():
            shutil.rmtree(self.build_dir)
            
        # 清理Linux特定的构建缓存
        linux_build_dir = self.linux_dir / "build"
        if linux_build_dir.exists():
            shutil.rmtree(linux_build_dir)
            
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
            
    def build_linux(self, build_mode="release"):
        """构建Linux应用"""
        print(f"🔨 构建Linux应用 - {build_mode} mode...")
        
        cmd = ['flutter', 'build', 'linux']
        
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
            print("✅ Linux构建成功")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Linux构建失败: {e}")
            return False
            
    def create_appimage(self, build_mode="release"):
        """创建AppImage包"""
        print("📦 创建AppImage包...")
        
        version, build_number = self.get_version_info()
        
        # 创建AppDir结构
        appdir = self.build_dir / "AppDir"
        appdir.mkdir(parents=True, exist_ok=True)
        
        # 复制应用文件
        app_source = self.project_root / "build" / "linux" / "x64" / "release" / "bundle"
        app_target = appdir / "usr" / "bin"
        app_target.mkdir(parents=True, exist_ok=True)
        
        if app_source.exists():
            shutil.copytree(app_source, app_target / "charasgem", dirs_exist_ok=True)
        else:
            print("❌ 构建产物不存在")
            return None
            
        # 创建desktop文件
        desktop_content = f"""[Desktop Entry]
Type=Application
Name=CharasGem
Comment=A versatile calligraphy management and practice application
Exec=charasgem
Icon=charasgem
Categories=Office;Education;
StartupNotify=true
"""
        
        desktop_file = appdir / "charasgem.desktop"
        with open(desktop_file, 'w') as f:
            f.write(desktop_content)
            
        # 复制图标
        icon_source = self.project_root / "assets" / "images" / "app_icon.png"
        icon_target = appdir / "charasgem.png"
        if icon_source.exists():
            shutil.copy2(icon_source, icon_target)
        else:
            # 创建占位符图标
            icon_target.write_text("# Icon placeholder")
            
        # 创建AppRun脚本
        apprun_content = """#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/charasgem/demo" "$@"
"""
        
        apprun_file = appdir / "AppRun"
        with open(apprun_file, 'w') as f:
            f.write(apprun_content)
        apprun_file.chmod(0o755)
        
        # 使用appimagetool创建AppImage
        appimage_name = f"CharasGem-v{version}-{build_number}-x86_64.AppImage"
        appimage_path = self.output_dir / appimage_name
        
        try:
            cmd = ['appimagetool', str(appdir), str(appimage_path)]
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print(f"✅ AppImage创建成功: {appimage_path}")
            return appimage_path
        except subprocess.CalledProcessError as e:
            print(f"❌ AppImage创建失败: {e}")
            return None
        except FileNotFoundError:
            print("⚠️ appimagetool未安装，跳过AppImage创建")
            return None
            
    def create_snap(self, build_mode="release"):
        """创建Snap包"""
        print("📦 创建Snap包...")
        
        version, build_number = self.get_version_info()
        
        # 创建snapcraft.yaml
        snapcraft_content = f"""name: charasgem
base: core20
version: '{version}'
summary: CharasGem - Calligraphy Practice App
description: |
  A versatile calligraphy management and practice application
  that helps users learn and practice Chinese calligraphy.

grade: stable
confinement: strict

architectures:
  - build-on: amd64

apps:
  charasgem:
    command: bin/demo
    extensions: [gnome-3-38]
    plugs:
      - home
      - desktop
      - desktop-legacy
      - x11
      - wayland
      - opengl
      - network
      - removable-media

parts:
  charasgem:
    plugin: dump
    source: build/linux/x64/release/bundle
    organize:
      '*': bin/
"""
        
        snap_dir = self.build_dir / "snap"
        snap_dir.mkdir(parents=True, exist_ok=True)
        
        snapcraft_file = snap_dir / "snapcraft.yaml"
        with open(snapcraft_file, 'w') as f:
            f.write(snapcraft_content)
            
        # 构建Snap包
        try:
            cmd = ['snapcraft', '--destructive-mode']
            result = subprocess.run(cmd, cwd=self.build_dir, check=True, 
                                  capture_output=True, text=True)
            
            # 移动生成的snap文件
            snap_files = list(self.build_dir.glob("*.snap"))
            if snap_files:
                snap_file = snap_files[0]
                target_snap = self.output_dir / f"charasgem-v{version}-{build_number}.snap"
                shutil.move(snap_file, target_snap)
                print(f"✅ Snap包创建成功: {target_snap}")
                return target_snap
            else:
                print("❌ 未找到生成的Snap文件")
                return None
                
        except subprocess.CalledProcessError as e:
            print(f"❌ Snap包创建失败: {e}")
            return None
        except FileNotFoundError:
            print("⚠️ snapcraft未安装，跳过Snap创建")
            return None
            
    def create_flatpak(self, build_mode="release"):
        """创建Flatpak包"""
        print("📦 创建Flatpak包...")
        
        version, build_number = self.get_version_info()
        
        # 创建Flatpak manifest
        manifest_content = {
            "app-id": "com.example.CharasGem",
            "runtime": "org.gnome.Platform",
            "runtime-version": "42",
            "sdk": "org.gnome.Sdk",
            "command": "charasgem",
            "finish-args": [
                "--share=ipc",
                "--socket=x11",
                "--socket=wayland",
                "--device=dri",
                "--filesystem=home",
                "--share=network"
            ],
            "modules": [
                {
                    "name": "charasgem",
                    "buildsystem": "simple",
                    "build-commands": [
                        "install -D demo /app/bin/charasgem",
                        "install -D -m644 ../charasgem.desktop /app/share/applications/com.example.CharasGem.desktop",
                        "install -D -m644 ../charasgem.png /app/share/icons/hicolor/256x256/apps/com.example.CharasGem.png"
                    ],
                    "sources": [
                        {
                            "type": "dir",
                            "path": "build/linux/x64/release/bundle"
                        }
                    ]
                }
            ]
        }
        
        flatpak_dir = self.build_dir / "flatpak"
        flatpak_dir.mkdir(parents=True, exist_ok=True)
        
        manifest_file = flatpak_dir / "com.example.CharasGem.json"
        with open(manifest_file, 'w') as f:
            json.dump(manifest_content, f, indent=2)
            
        # 构建Flatpak包
        try:
            cmd = [
                'flatpak-builder', '--force-clean',
                str(flatpak_dir / "build"),
                str(manifest_file)
            ]
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print("✅ Flatpak包创建成功")
            return flatpak_dir / "build"
        except subprocess.CalledProcessError as e:
            print(f"❌ Flatpak包创建失败: {e}")
            return None
        except FileNotFoundError:
            print("⚠️ flatpak-builder未安装，跳过Flatpak创建")
            return None
            
    def create_deb(self, build_mode="release"):
        """创建DEB包"""
        print("📦 创建DEB包...")
        
        version, build_number = self.get_version_info()
        
        # 创建DEB包结构
        deb_dir = self.build_dir / "deb"
        deb_dir.mkdir(parents=True, exist_ok=True)
        
        # DEBIAN控制目录
        debian_dir = deb_dir / "DEBIAN"
        debian_dir.mkdir(exist_ok=True)
        
        # 控制文件
        control_content = f"""Package: charasgem
Version: {version}-{build_number}
Section: education
Priority: optional
Architecture: amd64
Depends: libc6, libgtk-3-0, libglib2.0-0
Maintainer: Your Name <your.email@example.com>
Description: CharasGem - Calligraphy Practice Application
 A versatile calligraphy management and practice application
 that helps users learn and practice Chinese calligraphy.
"""
        
        with open(debian_dir / "control", 'w') as f:
            f.write(control_content)
            
        # 应用文件
        app_dir = deb_dir / "opt" / "charasgem"
        app_dir.mkdir(parents=True, exist_ok=True)
        
        app_source = self.project_root / "build" / "linux" / "x64" / "release" / "bundle"
        if app_source.exists():
            shutil.copytree(app_source, app_dir, dirs_exist_ok=True)
        else:
            print("❌ 构建产物不存在")
            return None
            
        # 桌面文件
        applications_dir = deb_dir / "usr" / "share" / "applications"
        applications_dir.mkdir(parents=True, exist_ok=True)
        
        desktop_content = f"""[Desktop Entry]
Type=Application
Name=CharasGem
Comment=Calligraphy Practice Application
Exec=/opt/charasgem/demo
Icon=charasgem
Categories=Office;Education;
StartupNotify=true
"""
        
        with open(applications_dir / "charasgem.desktop", 'w') as f:
            f.write(desktop_content)
            
        # 图标
        icons_dir = deb_dir / "usr" / "share" / "pixmaps"
        icons_dir.mkdir(parents=True, exist_ok=True)
        
        icon_source = self.project_root / "assets" / "images" / "app_icon.png"
        if icon_source.exists():
            shutil.copy2(icon_source, icons_dir / "charasgem.png")
            
        # 构建DEB包
        deb_name = f"charasgem-v{version}-{build_number}_amd64.deb"
        deb_path = self.output_dir / deb_name
        
        try:
            cmd = ['dpkg-deb', '--build', str(deb_dir), str(deb_path)]
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            print(f"✅ DEB包创建成功: {deb_path}")
            return deb_path
        except subprocess.CalledProcessError as e:
            print(f"❌ DEB包创建失败: {e}")
            return None
        except FileNotFoundError:
            print("⚠️ dpkg-deb未安装，跳过DEB创建")
            return None
            
    def create_rpm(self, build_mode="release"):
        """创建RPM包"""
        print("📦 创建RPM包...")
        
        version, build_number = self.get_version_info()
        
        # 创建RPM构建目录结构
        rpm_build_dir = self.build_dir / "rpmbuild"
        for subdir in ["BUILD", "RPMS", "SOURCES", "SPECS", "SRPMS"]:
            (rpm_build_dir / subdir).mkdir(parents=True, exist_ok=True)
            
        # 创建spec文件
        spec_content = f"""Name:           charasgem
Version:        {version}
Release:        {build_number}%{{?dist}}
Summary:        CharasGem - Calligraphy Practice Application

License:        MIT
URL:            https://github.com/yourname/charasgem
Source0:        %{{name}}-%{{version}}.tar.gz

BuildRequires:  gcc-c++
Requires:       gtk3, glib2

%description
A versatile calligraphy management and practice application
that helps users learn and practice Chinese calligraphy.

%prep
%setup -q

%build
# No build needed, using pre-built binaries

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/charasgem
mkdir -p $RPM_BUILD_ROOT/usr/share/applications
mkdir -p $RPM_BUILD_ROOT/usr/share/pixmaps

cp -r * $RPM_BUILD_ROOT/opt/charasgem/

cat > $RPM_BUILD_ROOT/usr/share/applications/charasgem.desktop << EOF
[Desktop Entry]
Type=Application
Name=CharasGem
Comment=Calligraphy Practice Application
Exec=/opt/charasgem/demo
Icon=charasgem
Categories=Office;Education;
StartupNotify=true
EOF

cp charasgem.png $RPM_BUILD_ROOT/usr/share/pixmaps/ || true

%files
/opt/charasgem/
/usr/share/applications/charasgem.desktop
/usr/share/pixmaps/charasgem.png

%changelog
* {datetime.now().strftime('%a %b %d %Y')} Your Name <your.email@example.com> - {version}-{build_number}
- Initial package
"""
        
        spec_file = rpm_build_dir / "SPECS" / "charasgem.spec"
        with open(spec_file, 'w') as f:
            f.write(spec_content)
            
        # 创建源码tar包
        app_source = self.project_root / "build" / "linux" / "x64" / "release" / "bundle"
        if not app_source.exists():
            print("❌ 构建产物不存在")
            return None
            
        # 使用tar创建源码包
        sources_dir = rpm_build_dir / "SOURCES"
        tar_name = f"charasgem-{version}.tar.gz"
        
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_source = Path(temp_dir) / f"charasgem-{version}"
            shutil.copytree(app_source, temp_source)
            
            # 添加图标
            icon_source = self.project_root / "assets" / "images" / "app_icon.png"
            if icon_source.exists():
                shutil.copy2(icon_source, temp_source / "charasgem.png")
                
            # 创建tar包
            cmd = ['tar', 'czf', str(sources_dir / tar_name), 
                   '-C', temp_dir, f"charasgem-{version}"]
            subprocess.run(cmd, check=True)
            
        # 构建RPM包
        try:
            cmd = [
                'rpmbuild', '-ba',
                '--define', f'_topdir {rpm_build_dir}',
                str(spec_file)
            ]
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            
            # 查找生成的RPM文件
            rpm_files = list((rpm_build_dir / "RPMS").rglob("*.rpm"))
            if rpm_files:
                rpm_file = rpm_files[0]
                target_rpm = self.output_dir / f"charasgem-v{version}-{build_number}.x86_64.rpm"
                shutil.copy2(rpm_file, target_rpm)
                print(f"✅ RPM包创建成功: {target_rpm}")
                return target_rpm
            else:
                print("❌ 未找到生成的RPM文件")
                return None
                
        except subprocess.CalledProcessError as e:
            print(f"❌ RPM包创建失败: {e}")
            return None
        except FileNotFoundError:
            print("⚠️ rpmbuild未安装，跳过RPM创建")
            return None
            
    def organize_outputs(self, build_mode="release"):
        """整理构建产物"""
        print("📦 整理构建产物...")
        
        version, build_number = self.get_version_info()
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 目标目录
        target_dir = self.output_dir / f"v{version}_build{build_number}_{timestamp}"
        target_dir.mkdir(parents=True, exist_ok=True)
        
        # 移动所有包文件到目标目录
        package_extensions = ['.AppImage', '.snap', '.deb', '.rpm']
        for package_file in self.output_dir.iterdir():
            if package_file.is_file() and any(package_file.name.endswith(ext) for ext in package_extensions):
                target_package = target_dir / package_file.name
                shutil.move(package_file, target_package)
                print(f"📦 {package_file.suffix.upper()}: {target_package}")
                
        # 复制原始构建产物
        bundle_source = self.project_root / "build" / "linux" / "x64" / "release" / "bundle"
        if bundle_source.exists():
            bundle_target = target_dir / "bundle"
            shutil.copytree(bundle_source, bundle_target)
            print(f"📁 Bundle: {bundle_target}")
            
        # 生成构建信息
        build_info = {
            "platform": "Linux",
            "version": version,
            "build_number": build_number,
            "build_mode": build_mode,
            "timestamp": timestamp,
            "files": [f.name for f in target_dir.iterdir()],
            "distribution": self.get_distribution_info()
        }
        
        with open(target_dir / "build_info.json", "w", encoding="utf-8") as f:
            json.dump(build_info, f, indent=2, ensure_ascii=False)
            
        print(f"✅ 构建产物已整理到: {target_dir}")
        return target_dir
        
    def generate_build_report(self):
        """生成构建报告"""
        print("📋 生成构建报告...")
        
        report = {
            "platform": "Linux",
            "timestamp": datetime.now().isoformat(),
            "environment": {
                "distribution": self.get_distribution_info(),
                "kernel_version": self.get_kernel_version(),
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
        
    def get_distribution_info(self):
        """获取Linux发行版信息"""
        try:
            with open('/etc/os-release', 'r') as f:
                lines = f.readlines()
                info = {}
                for line in lines:
                    if '=' in line:
                        key, value = line.strip().split('=', 1)
                        info[key] = value.strip('"')
                return f"{info.get('NAME', 'Unknown')} {info.get('VERSION', '')}"
        except:
            return "Unknown Linux"
            
    def get_kernel_version(self):
        """获取内核版本"""
        try:
            result = subprocess.run(['uname', '-r'], 
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
    parser = argparse.ArgumentParser(description="Linux平台构建脚本")
    parser.add_argument("--build-mode", choices=["debug", "profile", "release"], 
                       default="release", help="构建模式")
    parser.add_argument("--package-formats", nargs='+', 
                       choices=["appimage", "snap", "flatpak", "deb", "rpm", "all"], 
                       default=["appimage", "deb"], help="打包格式")
    parser.add_argument("--clean", action="store_true", 
                       help="构建前清理缓存")
    parser.add_argument("--check-env", action="store_true", 
                       help="仅检查构建环境")
    
    args = parser.parse_args()
    
    builder = LinuxBuilder()
    
    # 检查环境
    if args.check_env:
        if builder.check_environment():
            print("✅ Linux构建环境检查通过")
            sys.exit(0)
        else:
            print("❌ Linux构建环境检查失败")
            sys.exit(1)
            
    # 环境检查
    if not builder.check_environment():
        print("❌ 构建环境检查失败，请先配置Linux开发环境")
        sys.exit(1)
        
    # 清理构建
    if args.clean:
        builder.clean_build()
        
    # 执行构建
    try:
        # 构建Linux应用
        success = builder.build_linux(args.build_mode)
        
        if success:
            # 确定要创建的包格式
            formats = args.package_formats
            if "all" in formats:
                formats = ["appimage", "snap", "flatpak", "deb", "rpm"]
                
            # 创建各种格式的包
            for fmt in formats:
                if fmt == "appimage":
                    builder.create_appimage(args.build_mode)
                elif fmt == "snap":
                    builder.create_snap(args.build_mode)
                elif fmt == "flatpak":
                    builder.create_flatpak(args.build_mode)
                elif fmt == "deb":
                    builder.create_deb(args.build_mode)
                elif fmt == "rpm":
                    builder.create_rpm(args.build_mode)
                    
            # 整理输出
            builder.organize_outputs(args.build_mode)
            
        # 生成构建报告
        builder.generate_build_report()
        
        if success:
            print("\n🎉 Linux构建完成！")
            sys.exit(0)
        else:
            print("\n❌ Linux构建失败！")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n⚠️ 构建被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 构建过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 