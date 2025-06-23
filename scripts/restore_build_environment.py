#!/usr/bin/env python3
"""
构建环境快速恢复脚本
用于快速重建或修复各平台的构建环境
"""

import os
import sys
import subprocess
import json
import platform
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from enum import Enum

class PlatformType(Enum):
    ANDROID = "android"
    IOS = "ios"
    HARMONYOS = "harmonyos"
    WEB = "web"
    WINDOWS = "windows"
    MACOS = "macos"
    LINUX = "linux"

class RestoreAction(Enum):
    INSTALL = "install"
    CONFIGURE = "configure"
    REPAIR = "repair"
    CLEAN = "clean"

@dataclass
class RestoreStep:
    name: str
    description: str
    action: RestoreAction
    command: Optional[str] = None
    manual_instruction: Optional[str] = None
    success_check: Optional[str] = None

class BuildEnvironmentRestorer:
    def __init__(self):
        self.current_os = platform.system().lower()
        self.project_root = Path(__file__).parent.parent
        self.restore_log = []
        
    def log(self, message: str, level: str = "INFO"):
        """记录日志"""
        log_entry = f"[{level}] {message}"
        self.restore_log.append(log_entry)
        print(log_entry)
    
    def run_command(self, command: str, capture_output: bool = False) -> Tuple[bool, str]:
        """运行命令"""
        self.log(f"执行命令: {command}")
        try:
            if capture_output:
                result = subprocess.run(
                    command, shell=True, capture_output=True, text=True, 
                    timeout=300, encoding='utf-8', errors='ignore'
                )
                return result.returncode == 0, result.stdout.strip() if result.stdout else ""
            else:
                result = subprocess.run(command, shell=True, timeout=300)
                return result.returncode == 0, ""
        except subprocess.TimeoutExpired:
            self.log("命令执行超时", "ERROR")
            return False, "超时"
        except Exception as e:
            self.log(f"命令执行错误: {e}", "ERROR")
            return False, str(e)
    
    def restore_flutter_environment(self) -> bool:
        """恢复Flutter基础环境"""
        self.log("🔧 恢复Flutter基础环境...")
        
        steps = [
            RestoreStep(
                "清理Flutter缓存", "清理可能损坏的Flutter缓存",
                RestoreAction.CLEAN, "flutter clean"
            ),
            RestoreStep(
                "获取项目依赖", "获取项目所需的Dart包",
                RestoreAction.INSTALL, "flutter pub get"
            )
        ]
        
        success = True
        for step in steps:
            self.log(f"  执行步骤: {step.name}")
            
            if step.command:
                cmd_success, output = self.run_command(step.command, capture_output=True)
                if not cmd_success:
                    self.log(f"  步骤失败: {step.name}", "ERROR")
                    success = False
                    continue
            
            self.log(f"  ✅ 步骤完成: {step.name}")
        
        return success
    
    def restore_android_environment(self) -> bool:
        """恢复Android构建环境"""
        self.log("🤖 恢复Android构建环境...")
        
        # 检查是否存在Android项目
        android_dir = self.project_root / "android"
        if not android_dir.exists():
            self.log("  Android项目目录不存在，将创建...")
            success, _ = self.run_command("flutter create --platforms=android .")
            if not success:
                self.log("  创建Android项目失败", "ERROR")
                return False
        
        steps = [
            RestoreStep(
                "启用Android支持", "确保Flutter Android支持已启用",
                RestoreAction.CONFIGURE, "flutter config --enable-android"
            ),
            RestoreStep(
                "清理Android构建", "清理Android构建缓存",
                RestoreAction.CLEAN, "flutter clean"
            )
        ]
        
        success = True
        for step in steps:
            self.log(f"  执行步骤: {step.name}")
            
            if step.command:
                cmd_success, _ = self.run_command(step.command)
                if not cmd_success:
                    self.log(f"  步骤失败: {step.name}", "ERROR")
                    success = False
                    continue
            
            self.log(f"  ✅ 步骤完成: {step.name}")
        
        # 尝试构建测试
        self.log("  测试Android构建...")
        build_success, _ = self.run_command("flutter build apk --debug")
        if build_success:
            self.log("  ✅ Android构建测试成功")
        else:
            self.log("  ⚠️ Android构建测试失败，可能需要手动配置", "WARN")
            success = False
        
        return success
    
    def restore_web_environment(self) -> bool:
        """恢复Web构建环境"""
        self.log("🌐 恢复Web构建环境...")
        
        # 检查是否存在Web项目
        web_dir = self.project_root / "web"
        if not web_dir.exists():
            self.log("  Web项目目录不存在，将创建...")
            success, _ = self.run_command("flutter create --platforms=web .")
            if not success:
                self.log("  创建Web项目失败", "ERROR")
                return False
        
        steps = [
            RestoreStep(
                "启用Web支持", "确保Flutter Web支持已启用",
                RestoreAction.CONFIGURE, "flutter config --enable-web"
            )
        ]
        
        success = True
        for step in steps:
            self.log(f"  执行步骤: {step.name}")
            
            if step.command:
                cmd_success, _ = self.run_command(step.command)
                if not cmd_success:
                    self.log(f"  步骤失败: {step.name}", "ERROR")
                    success = False
                    continue
            
            self.log(f"  ✅ 步骤完成: {step.name}")
        
        # 尝试构建测试
        self.log("  测试Web构建...")
        build_success, _ = self.run_command("flutter build web")
        if build_success:
            self.log("  ✅ Web构建测试成功")
        else:
            self.log("  ⚠️ Web构建测试失败", "WARN")
            success = False
        
        return success
    
    def restore_all_platforms(self, platforms: Optional[List[str]] = None) -> Dict[str, bool]:
        """恢复所有或指定平台的构建环境"""
        self.log("🔧 开始恢复构建环境...")
        self.log("=" * 60)
        
        # 首先恢复Flutter基础环境
        flutter_success = self.restore_flutter_environment()
        if not flutter_success:
            self.log("❌ Flutter基础环境恢复失败，停止后续操作", "ERROR")
            return {"flutter": False}
        
        # 定义平台恢复器
        platform_restorers = {
            "android": self.restore_android_environment,
            "web": self.restore_web_environment,
        }
        
        # 确定要恢复的平台
        if platforms:
            target_platforms = [p for p in platforms if p in platform_restorers]
        else:
            target_platforms = list(platform_restorers.keys())
        
        results = {"flutter": flutter_success}
        
        for platform in target_platforms:
            self.log(f"\n{'='*20} {platform.upper()} {'='*20}")
            try:
                success = platform_restorers[platform]()
                results[platform] = success
                
                if success:
                    self.log(f"✅ {platform}环境恢复成功")
                else:
                    self.log(f"⚠️ {platform}环境恢复部分成功", "WARN")
                    
            except Exception as e:
                self.log(f"❌ {platform}环境恢复失败: {e}", "ERROR")
                results[platform] = False
        
        return results

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="构建环境快速恢复工具")
    parser.add_argument(
        "--platforms", "-p",
        nargs="+",
        choices=["android", "web"],
        help="指定要恢复的平台（默认恢复所有平台）"
    )
    
    args = parser.parse_args()
    
    restorer = BuildEnvironmentRestorer()
    
    try:
        # 恢复构建环境
        results = restorer.restore_all_platforms(args.platforms)
        
        # 显示总结
        print("\n" + "=" * 60)
        print("📋 恢复总结:")
        
        success_count = 0
        failed_count = 0
        
        for platform, success in results.items():
            status = "✅" if success else "❌"
            print(f"  {status} {platform.upper()}")
            
            if success:
                success_count += 1
            else:
                failed_count += 1
        
        print(f"\n✅ 成功: {success_count}  ❌ 失败: {failed_count}")
        
        if failed_count > 0:
            print("\n⚠️ 部分环境恢复失败，请查看日志并手动修复")
            print("💡 建议运行验证脚本检查具体问题：python scripts/verify_build_environment.py")
            sys.exit(1)
        else:
            print("\n🎉 所有环境恢复成功！")
            print("💡 建议运行验证脚本确认：python scripts/verify_build_environment.py")
            sys.exit(0)
            
    except KeyboardInterrupt:
        print("\n\n⏹️ 恢复被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 恢复过程出错: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 