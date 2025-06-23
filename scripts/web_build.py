#!/usr/bin/env python3
"""
Web平台构建脚本
支持PWA构建、优化、CDN部署等
"""

import os
import sys
import subprocess
import argparse
import json
import shutil
import gzip
from pathlib import Path
from datetime import datetime

class WebBuilder:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.web_dir = self.project_root / "web"
        self.build_dir = self.project_root / "build" / "web"
        self.output_dir = self.project_root / "releases" / "web"
        
        # 确保输出目录存在
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def check_environment(self):
        """检查Web构建环境"""
        print("🔍 检查Web构建环境...")
        
        # 检查Flutter
        try:
            # 在Windows上尝试不同的Flutter命令
            flutter_cmd = 'flutter'
            if os.name == 'nt':  # Windows
                # 尝试多种可能的Flutter命令
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
            else:
                result = subprocess.run(['flutter', '--version'], 
                                      capture_output=True, text=True, check=True)
                flutter_version = result.stdout.split()[1]
                print(f"✅ Flutter: {flutter_version}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("❌ Flutter未安装或不在PATH中")
            return False
            
        # 检查Flutter Web支持
        try:
            result = subprocess.run(['flutter', 'devices'], 
                                  capture_output=True, text=True, check=True)
            if "Chrome" in result.stdout or "Web Server" in result.stdout:
                print("✅ Flutter Web支持可用")
            else:
                print("⚠️ Flutter Web支持可能未启用")
        except:
            print("⚠️ 无法检查Flutter Web支持")
            
        # 检查Node.js (可选，用于高级优化)
        try:
            result = subprocess.run(['node', '--version'], 
                                  capture_output=True, text=True, check=True)
            node_version = result.stdout.strip()
            print(f"✅ Node.js: {node_version}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("⚠️ Node.js未安装（可选）")
            
        return True
        
    def clean_build(self):
        """清理构建缓存"""
        print("🧹 清理构建缓存...")
        
        # Flutter clean
        subprocess.run(['flutter', 'clean'], cwd=self.project_root)
        
        # 删除构建目录
        if self.build_dir.exists():
            shutil.rmtree(self.build_dir)
            
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
            
    def update_manifest(self):
        """更新Web manifest"""
        print("📝 更新Web manifest...")
        
        version, build_number = self.get_version_info()
        manifest_path = self.web_dir / "manifest.json"
        
        if manifest_path.exists():
            with open(manifest_path, "r", encoding="utf-8") as f:
                manifest = json.load(f)
                
            # 更新版本信息
            manifest["version"] = version
            manifest["version_name"] = f"{version}-{build_number}"
            
            # 添加构建时间戳
            manifest["build_timestamp"] = datetime.now().isoformat()
            
            with open(manifest_path, "w", encoding="utf-8") as f:
                json.dump(manifest, f, indent=2, ensure_ascii=False)
                
            print(f"✅ Manifest已更新 - 版本: {version}, 构建号: {build_number}")
        else:
            print("⚠️ manifest.json文件不存在")
            
    def build_web(self, build_mode="release", renderer="canvaskit"):
        """构建Web应用"""
        print(f"🔨 构建Web应用 - {build_mode} mode with {renderer} renderer...")
        
        # 更新manifest
        self.update_manifest()
        
        cmd = ['flutter', 'build', 'web']
        
        # 构建模式
        if build_mode == "debug":
            cmd.append('--debug')
        elif build_mode == "profile":
            cmd.append('--profile')
        else:
            cmd.append('--release')
            
        # 渲染器选择
        cmd.extend(['--web-renderer', renderer])
        
        # 优化选项
        if build_mode == "release":
            cmd.extend([
                '--tree-shake-icons',  # 树摇图标
                '--dart-define=flutter.inspector.structuredErrors=false'  # 禁用调试信息
            ])
            
        # 执行构建
        try:
            result = subprocess.run(cmd, cwd=self.project_root, check=True)
            print("✅ Web构建成功")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Web构建失败: {e}")
            return False
            
    def optimize_build(self):
        """优化构建产物"""
        print("⚡ 优化构建产物...")
        
        if not self.build_dir.exists():
            print("❌ 构建目录不存在")
            return False
            
        # 压缩静态资源
        self.compress_assets()
        
        # 生成Service Worker
        self.generate_service_worker()
        
        # 优化图片
        self.optimize_images()
        
        print("✅ 构建产物优化完成")
        return True
        
    def compress_assets(self):
        """压缩静态资源"""
        print("📦 压缩静态资源...")
        
        # 需要压缩的文件类型
        compress_extensions = ['.js', '.css', '.html', '.json', '.svg', '.txt']
        
        for file_path in self.build_dir.rglob('*'):
            if file_path.is_file() and file_path.suffix in compress_extensions:
                # 创建gzip压缩版本
                gzip_path = file_path.with_suffix(file_path.suffix + '.gz')
                
                with open(file_path, 'rb') as f_in:
                    with gzip.open(gzip_path, 'wb') as f_out:
                        shutil.copyfileobj(f_in, f_out)
                        
                # 检查压缩效果
                original_size = file_path.stat().st_size
                compressed_size = gzip_path.stat().st_size
                ratio = (1 - compressed_size / original_size) * 100
                
                if ratio > 20:  # 压缩率超过20%才保留
                    print(f"  📦 {file_path.name}: {original_size} → {compressed_size} ({ratio:.1f}%)")
                else:
                    gzip_path.unlink()  # 删除压缩效果不好的文件
                    
    def generate_service_worker(self):
        """生成Service Worker"""
        print("🔧 生成Service Worker...")
        
        service_worker_content = '''
// Service Worker for CharasGem PWA
const CACHE_NAME = 'charasgem-v{version}';
const CACHE_URLS = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/flutter.js',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png'
];

// 安装事件
self.addEventListener('install', event => {
  console.log('Service Worker: Installing...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Service Worker: Caching files');
        return cache.addAll(CACHE_URLS);
      })
      .then(() => self.skipWaiting())
  );
});

// 激活事件
self.addEventListener('activate', event => {
  console.log('Service Worker: Activating...');
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('Service Worker: Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// 获取事件
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // 缓存命中，返回缓存的资源
        if (response) {
          return response;
        }
        
        // 缓存未命中，从网络获取
        return fetch(event.request).then(response => {
          // 检查是否是有效响应
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }
          
          // 克隆响应
          const responseToCache = response.clone();
          
          // 添加到缓存
          caches.open(CACHE_NAME)
            .then(cache => {
              cache.put(event.request, responseToCache);
            });
          
          return response;
        });
      })
  );
});

// 后台同步
self.addEventListener('sync', event => {
  if (event.tag === 'background-sync') {
    event.waitUntil(doBackgroundSync());
  }
});

function doBackgroundSync() {
  // 实现后台同步逻辑
  console.log('Service Worker: Background sync');
}

// 推送通知
self.addEventListener('push', event => {
  if (event.data) {
    const data = event.data.json();
    const options = {
      body: data.body,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-96.png',
      vibrate: [100, 50, 100],
      data: data.data
    };
    
    event.waitUntil(
      self.registration.showNotification(data.title, options)
    );
  }
});

// 通知点击
self.addEventListener('notificationclick', event => {
  event.notification.close();
  
  event.waitUntil(
    clients.openWindow(event.notification.data.url || '/')
  );
});
'''.format(version=self.get_version_info()[0])
        
        sw_path = self.build_dir / "sw.js"
        with open(sw_path, "w", encoding="utf-8") as f:
            f.write(service_worker_content)
            
        print("✅ Service Worker已生成")
        
    def optimize_images(self):
        """优化图片"""
        print("🖼️ 优化图片...")
        
        # 这里可以集成图片优化工具，如imagemin
        # 由于需要额外依赖，这里只做占位实现
        image_extensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp']
        image_count = 0
        
        for file_path in self.build_dir.rglob('*'):
            if file_path.is_file() and file_path.suffix.lower() in image_extensions:
                image_count += 1
                
        if image_count > 0:
            print(f"  📸 发现 {image_count} 个图片文件")
            print("  💡 提示: 可以使用imagemin等工具进一步优化图片")
        else:
            print("  📸 未发现需要优化的图片")
            
    def create_deployment_package(self, package_type="zip"):
        """创建部署包"""
        print(f"📦 创建{package_type.upper()}部署包...")
        
        version, build_number = self.get_version_info()
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 目标目录
        target_dir = self.output_dir / f"v{version}_build{build_number}_{timestamp}"
        target_dir.mkdir(parents=True, exist_ok=True)
        
        if package_type == "zip":
            # 创建ZIP包
            import zipfile
            
            zip_path = target_dir / f"charasgem-web-v{version}.zip"
            with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for file_path in self.build_dir.rglob('*'):
                    if file_path.is_file():
                        arc_path = file_path.relative_to(self.build_dir)
                        zipf.write(file_path, arc_path)
                        
            print(f"📦 ZIP包已创建: {zip_path}")
            
        elif package_type == "tar":
            # 创建TAR.GZ包
            import tarfile
            
            tar_path = target_dir / f"charasgem-web-v{version}.tar.gz"
            with tarfile.open(tar_path, 'w:gz') as tarf:
                tarf.add(self.build_dir, arcname='.')
                
            print(f"📦 TAR.GZ包已创建: {tar_path}")
            
        else:
            # 直接复制文件夹
            web_output_dir = target_dir / "web"
            shutil.copytree(self.build_dir, web_output_dir)
            print(f"📦 Web文件已复制到: {web_output_dir}")
            
        # 生成部署信息
        deploy_info = {
            "platform": "Web",
            "version": version,
            "build_number": build_number,
            "timestamp": timestamp,
            "package_type": package_type,
            "build_size": self.get_directory_size(self.build_dir),
            "files_count": sum(1 for _ in self.build_dir.rglob('*') if _.is_file())
        }
        
        with open(target_dir / "deploy_info.json", "w", encoding="utf-8") as f:
            json.dump(deploy_info, f, indent=2, ensure_ascii=False)
            
        print(f"✅ 部署包已创建: {target_dir}")
        return target_dir
        
    def get_directory_size(self, directory):
        """获取目录大小"""
        total_size = 0
        for file_path in directory.rglob('*'):
            if file_path.is_file():
                total_size += file_path.stat().st_size
        return total_size
        
    def deploy_to_server(self, server_config):
        """部署到服务器"""
        print("🚀 部署到服务器...")
        
        # 这里可以实现FTP、SFTP、rsync等部署方式
        # 示例实现使用rsync
        if server_config.get('method') == 'rsync':
            cmd = [
                'rsync', '-avz', '--delete',
                str(self.build_dir) + '/',
                f"{server_config['user']}@{server_config['host']}:{server_config['path']}"
            ]
            
            try:
                result = subprocess.run(cmd, check=True)
                print("✅ 部署成功")
                return True
            except subprocess.CalledProcessError as e:
                print(f"❌ 部署失败: {e}")
                return False
        else:
            print("⚠️ 不支持的部署方式")
            return False
            
    def generate_build_report(self):
        """生成构建报告"""
        print("📋 生成构建报告...")
        
        report = {
            "platform": "Web",
            "timestamp": datetime.now().isoformat(),
            "environment": {
                "flutter_version": self.get_flutter_version(),
                "dart_version": self.get_dart_version(),
                "build_size": self.get_directory_size(self.build_dir) if self.build_dir.exists() else 0
            },
            "builds": []
        }
        
        # 扫描构建产物
        for build_dir in self.output_dir.iterdir():
            if build_dir.is_dir():
                deploy_info_file = build_dir / "deploy_info.json"
                if deploy_info_file.exists():
                    with open(deploy_info_file, "r", encoding="utf-8") as f:
                        deploy_info = json.load(f)
                        report["builds"].append(deploy_info)
                        
        # 保存报告
        report_file = self.output_dir / f"build_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_file, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
            
        print(f"✅ 构建报告已生成: {report_file}")
        return report_file
        
    def get_flutter_version(self):
        """获取Flutter版本"""
        try:
            result = subprocess.run(['flutter', '--version'], 
                                  capture_output=True, text=True, check=True)
            return result.stdout.split()[1]
        except:
            return "Unknown"
            
    def get_dart_version(self):
        """获取Dart版本"""
        try:
            result = subprocess.run(['dart', '--version'], 
                                  capture_output=True, text=True, check=True)
            return result.stdout.split()[3]
        except:
            return "Unknown"

def main():
    parser = argparse.ArgumentParser(description="Web平台构建脚本")
    parser.add_argument("--build-mode", choices=["debug", "profile", "release"], 
                       default="release", help="构建模式")
    parser.add_argument("--renderer", choices=["canvaskit", "html"], 
                       default="canvaskit", help="Web渲染器")
    parser.add_argument("--package-type", choices=["zip", "tar", "folder"], 
                       default="zip", help="部署包类型")
    parser.add_argument("--optimize", action="store_true", 
                       help="优化构建产物")
    parser.add_argument("--deploy", help="部署配置文件路径")
    parser.add_argument("--clean", action="store_true", 
                       help="构建前清理缓存")
    parser.add_argument("--check-env", action="store_true", 
                       help="仅检查构建环境")
    
    args = parser.parse_args()
    
    builder = WebBuilder()
    
    # 检查环境
    if args.check_env:
        if builder.check_environment():
            print("✅ Web构建环境检查通过")
            sys.exit(0)
        else:
            print("❌ Web构建环境检查失败")
            sys.exit(1)
            
    # 环境检查
    if not builder.check_environment():
        print("❌ 构建环境检查失败，请先配置Web开发环境")
        sys.exit(1)
        
    # 清理构建
    if args.clean:
        builder.clean_build()
        
    # 执行构建
    try:
        # 构建Web应用
        success = builder.build_web(args.build_mode, args.renderer)
        
        if success:
            # 优化构建产物
            if args.optimize:
                builder.optimize_build()
                
            # 创建部署包
            output_dir = builder.create_deployment_package(args.package_type)
            
            # 部署到服务器
            if args.deploy:
                with open(args.deploy, "r", encoding="utf-8") as f:
                    server_config = json.load(f)
                builder.deploy_to_server(server_config)
                
        # 生成构建报告
        builder.generate_build_report()
        
        if success:
            print("\n🎉 Web构建完成！")
            sys.exit(0)
        else:
            print("\n❌ Web构建失败！")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n⚠️ 构建被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 构建过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 