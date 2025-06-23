#!/usr/bin/env python3
"""
构建环境验证脚本
验证所有平台的构建环境是否配置正确
"""

import os
import sys
import subprocess
import json
import platform
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

class CheckResult(Enum):
    PASS = "✅"
    FAIL = "❌"
    WARNING = "⚠️"
    SKIP = "⏭️"

@dataclass
class EnvironmentCheck:
    name: str
    description: str
    result: CheckResult
    message: str
    fix_suggestion: Optional[str] = None

@dataclass
class PlatformEnvironment:
    platform: PlatformType
    checks: List[EnvironmentCheck]
    overall_status: CheckResult
    
    @property
    def is_ready(self) -> bool:
        return self.overall_status in [CheckResult.PASS, CheckResult.WARNING]

class BuildEnvironmentVerifier:
    def __init__(self):
        self.current_os = platform.system().lower()
        self.project_root = Path(__file__).parent.parent
        self.results: Dict[PlatformType, PlatformEnvironment] = {}
        
    def run_command(self, command: str, capture_output: bool = True) -> Tuple[bool, str]:
        """运行命令并返回结果"""
        try:
            if capture_output:
                result = subprocess.run(
                    command, shell=True, capture_output=True, text=True, 
                    timeout=30, encoding='utf-8', errors='ignore'
                )
                return result.returncode == 0, result.stdout.strip()
            else:
                result = subprocess.run(command, shell=True, timeout=30)
                return result.returncode == 0, ""
        except subprocess.TimeoutExpired:
            return False, "命令执行超时"
        except Exception as e:
            return False, str(e)
    
    def check_flutter_environment(self) -> List[EnvironmentCheck]:
        """检查Flutter基础环境"""
        checks = []
        
        # 检查Flutter是否安装
        success, output = self.run_command("flutter --version")
        if success:
            version_line = output.split('\n')[0] if output else ""
            checks.append(EnvironmentCheck(
                "Flutter安装", "检查Flutter是否正确安装",
                CheckResult.PASS, f"已安装: {version_line}"
            ))
        else:
            checks.append(EnvironmentCheck(
                "Flutter安装", "检查Flutter是否正确安装",
                CheckResult.FAIL, "Flutter未安装或不在PATH中",
                "请安装Flutter SDK并添加到PATH环境变量"
            ))
            return checks
        
        # 检查Flutter doctor
        success, output = self.run_command("flutter doctor --machine")
        if success:
            try:
                doctor_data = json.loads(output)
                issues = []
                for check in doctor_data:
                    if check['status'] == 'installed':
                        continue
                    elif check['status'] == 'partial':
                        issues.append(f"{check['name']}: 部分配置")
                    elif check['status'] == 'notAvailable':
                        issues.append(f"{check['name']}: 未安装")
                
                if not issues:
                    checks.append(EnvironmentCheck(
                        "Flutter Doctor", "检查Flutter环境配置",
                        CheckResult.PASS, "所有检查项通过"
                    ))
                else:
                    checks.append(EnvironmentCheck(
                        "Flutter Doctor", "检查Flutter环境配置",
                        CheckResult.WARNING, f"存在问题: {', '.join(issues)}",
                        "运行 'flutter doctor' 查看详细信息并修复"
                    ))
            except json.JSONDecodeError:
                checks.append(EnvironmentCheck(
                    "Flutter Doctor", "检查Flutter环境配置",
                    CheckResult.WARNING, "无法解析doctor输出",
                    "手动运行 'flutter doctor' 检查环境"
                ))
        
        return checks
    
    def check_android_environment(self) -> PlatformEnvironment:
        """检查Android构建环境"""
        checks = []
        
        # 检查Android SDK
        android_home = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
        if android_home and os.path.exists(android_home):
            checks.append(EnvironmentCheck(
                "Android SDK", "检查Android SDK安装",
                CheckResult.PASS, f"SDK路径: {android_home}"
            ))
        else:
            checks.append(EnvironmentCheck(
                "Android SDK", "检查Android SDK安装",
                CheckResult.FAIL, "Android SDK未安装或环境变量未设置",
                "安装Android Studio或Android SDK，并设置ANDROID_HOME环境变量"
            ))
        
        # 检查Java环境
        success, output = self.run_command("java -version")
        if success:
            checks.append(EnvironmentCheck(
                "Java JDK", "检查Java开发环境",
                CheckResult.PASS, "Java环境可用"
            ))
        else:
            checks.append(EnvironmentCheck(
                "Java JDK", "检查Java开发环境",
                CheckResult.FAIL, "Java环境未配置",
                "安装Java JDK 11或更高版本"
            ))
        
        overall = CheckResult.PASS
        if any(check.result == CheckResult.FAIL for check in checks):
            overall = CheckResult.FAIL
        elif any(check.result == CheckResult.WARNING for check in checks):
            overall = CheckResult.WARNING
            
        return PlatformEnvironment(PlatformType.ANDROID, checks, overall)
    
    def check_ios_environment(self) -> PlatformEnvironment:
        """检查iOS构建环境"""
        checks = []
        
        if self.current_os != "darwin":
            checks.append(EnvironmentCheck(
                "macOS系统", "iOS构建需要macOS系统",
                CheckResult.SKIP, "当前系统不是macOS，跳过iOS检查"
            ))
            return PlatformEnvironment(PlatformType.IOS, checks, CheckResult.SKIP)
        
        # 检查Xcode
        success, output = self.run_command("xcodebuild -version")
        if success:
            version_line = output.split('\n')[0] if output else ""
            checks.append(EnvironmentCheck(
                "Xcode", "检查Xcode开发环境",
                CheckResult.PASS, f"已安装: {version_line}"
            ))
        else:
            checks.append(EnvironmentCheck(
                "Xcode", "检查Xcode开发环境",
                CheckResult.FAIL, "Xcode未安装",
                "从App Store安装Xcode"
            ))
        
        overall = CheckResult.PASS
        if any(check.result == CheckResult.FAIL for check in checks):
            overall = CheckResult.FAIL
        elif any(check.result == CheckResult.WARNING for check in checks):
            overall = CheckResult.WARNING
            
        return PlatformEnvironment(PlatformType.IOS, checks, overall)
    
    def check_web_environment(self) -> PlatformEnvironment:
        """检查Web构建环境"""
        checks = []
        
        # 检查Flutter Web支持
        success, output = self.run_command("flutter config --list")
        if success and "enable-web: true" in output:
            checks.append(EnvironmentCheck(
                "Flutter Web", "检查Flutter Web支持",
                CheckResult.PASS, "Flutter Web已启用"
            ))
        else:
            checks.append(EnvironmentCheck(
                "Flutter Web", "检查Flutter Web支持",
                CheckResult.WARNING, "Flutter Web未启用",
                "运行 'flutter config --enable-web' 启用Web支持"
            ))
        
        overall = CheckResult.PASS
        if any(check.result == CheckResult.FAIL for check in checks):
            overall = CheckResult.FAIL
        elif any(check.result == CheckResult.WARNING for check in checks):
            overall = CheckResult.WARNING
            
        return PlatformEnvironment(PlatformType.WEB, checks, overall)
    
    def verify_all_platforms(self) -> Dict[PlatformType, PlatformEnvironment]:
        """验证所有平台环境"""
        print("🔍 开始验证构建环境...")
        print("=" * 60)
        
        # 检查Flutter基础环境
        flutter_checks = self.check_flutter_environment()
        print("\n📱 Flutter基础环境:")
        for check in flutter_checks:
            print(f"  {check.result.value} {check.name}: {check.message}")
            if check.fix_suggestion:
                print(f"    💡 建议: {check.fix_suggestion}")
        
        # 检查各平台环境
        platform_checkers = {
            PlatformType.ANDROID: self.check_android_environment,
            PlatformType.IOS: self.check_ios_environment,
            PlatformType.WEB: self.check_web_environment,
        }
        
        for platform_type, checker in platform_checkers.items():
            print(f"\n🔧 {platform_type.value.upper()}平台环境:")
            platform_env = checker()
            self.results[platform_type] = platform_env
            
            for check in platform_env.checks:
                print(f"  {check.result.value} {check.name}: {check.message}")
                if check.fix_suggestion:
                    print(f"    💡 建议: {check.fix_suggestion}")
            
            print(f"  📊 平台状态: {platform_env.overall_status.value}")
        
        return self.results

def main():
    """主函数"""
    verifier = BuildEnvironmentVerifier()
    
    try:
        # 验证所有平台
        results = verifier.verify_all_platforms()
        
        # 显示总结
        print("\n" + "=" * 60)
        print("📋 验证总结:")
        
        ready_count = 0
        warning_count = 0
        failed_count = 0
        skipped_count = 0
        
        for platform_type, env in results.items():
            status_icon = env.overall_status.value
            print(f"  {status_icon} {platform_type.value.upper()}")
            
            if env.overall_status == CheckResult.PASS:
                ready_count += 1
            elif env.overall_status == CheckResult.WARNING:
                warning_count += 1
            elif env.overall_status == CheckResult.FAIL:
                failed_count += 1
            elif env.overall_status == CheckResult.SKIP:
                skipped_count += 1
        
        print(f"\n✅ 就绪: {ready_count}  ⚠️ 警告: {warning_count}  ❌ 失败: {failed_count}  ⏭️ 跳过: {skipped_count}")
        
        if failed_count > 0:
            print("\n❌ 存在构建环境问题，请查看详细信息并修复")
            sys.exit(1)
        elif warning_count > 0:
            print("\n⚠️ 构建环境基本可用，但建议修复警告项")
            sys.exit(0)
        else:
            print("\n🎉 所有可用平台的构建环境都已就绪！")
            sys.exit(0)
            
    except KeyboardInterrupt:
        print("\n\n⏹️ 验证被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 验证过程出错: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 