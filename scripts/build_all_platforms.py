#!/usr/bin/env python3
"""
多平台构建管理脚本
统一管理所有平台的构建过程，支持并行构建和构建产物管理
"""

import os
import sys
import subprocess
import json
import platform
import threading
import time
import yaml
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, asdict
from enum import Enum
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime

class PlatformType(Enum):
    ANDROID = "android"
    IOS = "ios"
    HARMONYOS = "harmonyos"
    WEB = "web"
    WINDOWS = "windows"
    MACOS = "macos"
    LINUX = "linux"

class BuildType(Enum):
    DEBUG = "debug"
    RELEASE = "release"

class BuildStatus(Enum):
    PENDING = "pending"
    BUILDING = "building"
    SUCCESS = "success"
    FAILED = "failed"
    SKIPPED = "skipped"

@dataclass
class BuildResult:
    platform: PlatformType
    build_type: BuildType
    status: BuildStatus
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    duration: Optional[float] = None
    artifacts: List[str] = None
    error_message: Optional[str] = None
    log_file: Optional[str] = None
    
    def __post_init__(self):
        if self.artifacts is None:
            self.artifacts = []
    
    @property
    def is_success(self) -> bool:
        return self.status == BuildStatus.SUCCESS
    
    @property
    def is_failed(self) -> bool:
        return self.status == BuildStatus.FAILED

class PlatformBuilder:
    def __init__(self, platform: PlatformType, build_type: BuildType, project_root: Path):
        self.platform = platform
        self.build_type = build_type
        self.project_root = project_root
        import platform as py_platform
        self.current_os = py_platform.system().lower()
        
    def can_build(self) -> Tuple[bool, str]:
        """检查当前环境是否支持该平台构建"""
        platform_os_requirements = {
            PlatformType.ANDROID: ["windows", "macos", "linux"],
            PlatformType.IOS: ["darwin"],
            PlatformType.HARMONYOS: ["windows", "macos", "linux"],
            PlatformType.WEB: ["windows", "macos", "linux"],
            PlatformType.WINDOWS: ["windows"],
            PlatformType.MACOS: ["darwin"],
            PlatformType.LINUX: ["linux"]
        }
        
        required_os = platform_os_requirements.get(self.platform, [])
        if self.current_os not in required_os:
            return False, f"{self.platform.value}构建需要{required_os}系统，当前系统：{self.current_os}"
        
        # 检查平台项目目录是否存在
        platform_dir = self.project_root / self.platform.value
        if not platform_dir.exists() and self.platform != PlatformType.WEB:
            return False, f"{self.platform.value}项目目录不存在：{platform_dir}"
        
        return True, "环境检查通过"
    
    def get_build_command(self) -> str:
        """获取平台特定的构建命令"""
        commands = {
            PlatformType.ANDROID: {
                BuildType.DEBUG: "flutter build apk --debug",
                BuildType.RELEASE: "flutter build appbundle --release"
            },
            PlatformType.IOS: {
                BuildType.DEBUG: "flutter build ios --debug --no-codesign",
                BuildType.RELEASE: "flutter build ipa --release"
            },
            PlatformType.HARMONYOS: {
                BuildType.DEBUG: "echo 'HarmonyOS debug build not implemented'",
                BuildType.RELEASE: "echo 'HarmonyOS release build not implemented'"
            },
            PlatformType.WEB: {
                BuildType.DEBUG: "flutter build web --debug",
                BuildType.RELEASE: "flutter build web --release"
            },
            PlatformType.WINDOWS: {
                BuildType.DEBUG: "flutter build windows --debug",
                BuildType.RELEASE: "flutter build windows --release"
            },
            PlatformType.MACOS: {
                BuildType.DEBUG: "flutter build macos --debug",
                BuildType.RELEASE: "flutter build macos --release"
            },
            PlatformType.LINUX: {
                BuildType.DEBUG: "flutter build linux --debug",
                BuildType.RELEASE: "flutter build linux --release"
            }
        }
        
        return commands.get(self.platform, {}).get(self.build_type, "echo 'Build command not defined'")
    
    def get_expected_artifacts(self) -> List[str]:
        """获取构建产物路径"""
        artifacts = {
            PlatformType.ANDROID: {
                BuildType.DEBUG: ["build/app/outputs/flutter-apk/app-debug.apk"],
                BuildType.RELEASE: ["build/app/outputs/bundle/release/app-release.aab"]
            },
            PlatformType.IOS: {
                BuildType.DEBUG: ["build/ios/iphoneos/Runner.app"],
                BuildType.RELEASE: ["build/ios/ipa/Runner.ipa"]
            },
            PlatformType.WEB: {
                BuildType.DEBUG: ["build/web/"],
                BuildType.RELEASE: ["build/web/"]
            },
            PlatformType.WINDOWS: {
                BuildType.DEBUG: ["build/windows/runner/Debug/"],
                BuildType.RELEASE: ["build/windows/runner/Release/"]
            },
            PlatformType.MACOS: {
                BuildType.DEBUG: ["build/macos/Build/Products/Debug/demo.app"],
                BuildType.RELEASE: ["build/macos/Build/Products/Release/demo.app"]
            },
            PlatformType.LINUX: {
                BuildType.DEBUG: ["build/linux/debug/bundle/"],
                BuildType.RELEASE: ["build/linux/release/bundle/"]
            },
            PlatformType.HARMONYOS: {
                BuildType.DEBUG: ["ohos/entry/build/default/outputs/default/entry-default-unsigned.hap"],
                BuildType.RELEASE: ["ohos/entry/build/default/outputs/default/entry-default-signed.hap"]
            }
        }
        
        return artifacts.get(self.platform, {}).get(self.build_type, [])
    
    def run_command(self, command: str, log_file: Path) -> Tuple[bool, str]:
        """运行构建命令并记录日志"""
        try:
            with open(log_file, 'w', encoding='utf-8') as f:
                f.write(f"构建命令: {command}\n")
                f.write(f"开始时间: {datetime.now()}\n")
                f.write("=" * 60 + "\n")
                
                result = subprocess.run(
                    command, shell=True, cwd=self.project_root,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    text=True, encoding='utf-8', errors='ignore'
                )
                
                f.write(result.stdout)
                f.write("\n" + "=" * 60 + "\n")
                f.write(f"结束时间: {datetime.now()}\n")
                f.write(f"返回码: {result.returncode}\n")
                
                return result.returncode == 0, result.stdout
                
        except Exception as e:
            error_msg = f"命令执行异常: {e}"
            with open(log_file, 'a', encoding='utf-8') as f:
                f.write(f"\n错误: {error_msg}\n")
            return False, error_msg
    
    def verify_artifacts(self) -> List[str]:
        """验证构建产物是否存在"""
        expected_artifacts = self.get_expected_artifacts()
        existing_artifacts = []
        
        for artifact_path in expected_artifacts:
            full_path = self.project_root / artifact_path
            if full_path.exists():
                existing_artifacts.append(artifact_path)
        
        return existing_artifacts
    
    def build(self) -> BuildResult:
        """执行平台构建"""
        result = BuildResult(
            platform=self.platform,
            build_type=self.build_type,
            status=BuildStatus.PENDING,
            start_time=datetime.now()
        )
        
        # 检查构建环境
        can_build, check_message = self.can_build()
        if not can_build:
            result.status = BuildStatus.SKIPPED
            result.error_message = check_message
            result.end_time = datetime.now()
            result.duration = 0
            return result
        
        # 设置日志文件
        logs_dir = self.project_root / "build_logs"
        logs_dir.mkdir(exist_ok=True)
        log_file = logs_dir / f"{self.platform.value}_{self.build_type.value}_{int(time.time())}.log"
        result.log_file = str(log_file)
        
        # 开始构建
        result.status = BuildStatus.BUILDING
        command = self.get_build_command()
        
        success, output = self.run_command(command, log_file)
        
        # 更新结果
        result.end_time = datetime.now()
        result.duration = (result.end_time - result.start_time).total_seconds()
        
        if success:
            result.status = BuildStatus.SUCCESS
            result.artifacts = self.verify_artifacts()
        else:
            result.status = BuildStatus.FAILED
            result.error_message = "构建失败，查看日志文件获取详细信息"
        
        return result

class MultiPlatformBuilder:
    def __init__(self, project_root: Optional[Path] = None):
        self.project_root = project_root or Path.cwd()
        self.config = self.load_config()
        self.results: Dict[str, BuildResult] = {}
        
    def load_config(self) -> Dict[str, Any]:
        """加载构建配置"""
        config_file = self.project_root / "config" / "build_environments.yaml"
        if config_file.exists():
            with open(config_file, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        return {}
    
    def get_available_platforms(self) -> List[PlatformType]:
        """获取当前环境可用的平台"""
        available = []
        current_os = platform.system().lower()
        
        # 检查配置文件中启用的平台
        platforms_config = self.config.get('platforms', {})
        
        for platform_type in PlatformType:
            platform_config = platforms_config.get(platform_type.value, {})
            if not platform_config.get('enabled', True):
                continue
                
            required_os = platform_config.get('requirements', {}).get('os', [])
            if current_os in required_os or not required_os:
                available.append(platform_type)
        
        return available
    
    def build_platform(self, platform: PlatformType, build_type: BuildType) -> BuildResult:
        """构建单个平台"""
        builder = PlatformBuilder(platform, build_type, self.project_root)
        return builder.build()
    
    def build_platforms_parallel(self, platforms: List[PlatformType], 
                                build_type: BuildType, max_workers: int = 3) -> Dict[str, BuildResult]:
        """并行构建多个平台"""
        results = {}
        
        print(f"🔨 开始并行构建 {len(platforms)} 个平台...")
        print(f"📦 构建类型: {build_type.value}")
        print(f"⚡ 最大并行数: {max_workers}")
        print("=" * 60)
        
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            # 提交构建任务
            future_to_platform = {
                executor.submit(self.build_platform, platform, build_type): platform
                for platform in platforms
            }
            
            # 收集结果
            for future in as_completed(future_to_platform):
                platform = future_to_platform[future]
                try:
                    result = future.result()
                    results[f"{platform.value}_{build_type.value}"] = result
                    
                    # 显示构建结果
                    status_icon = {
                        BuildStatus.SUCCESS: "✅",
                        BuildStatus.FAILED: "❌",
                        BuildStatus.SKIPPED: "⏭️"
                    }.get(result.status, "❓")
                    
                    duration_str = f"({result.duration:.1f}s)" if result.duration else ""
                    print(f"{status_icon} {platform.value.upper()} {build_type.value}: {result.status.value} {duration_str}")
                    
                    if result.error_message:
                        print(f"   💬 {result.error_message}")
                    
                    if result.artifacts:
                        print(f"   📁 产物: {len(result.artifacts)} 个文件")
                    
                except Exception as e:
                    print(f"❌ {platform.value.upper()} 构建异常: {e}")
                    results[f"{platform.value}_{build_type.value}"] = BuildResult(
                        platform=platform,
                        build_type=build_type,
                        status=BuildStatus.FAILED,
                        error_message=str(e)
                    )
        
        return results
    
    def build_all(self, build_type: BuildType = BuildType.DEBUG, 
                  platforms: Optional[List[str]] = None,
                  max_workers: int = 3) -> Dict[str, BuildResult]:
        """构建所有或指定平台"""
        
        # 确定要构建的平台
        if platforms:
            target_platforms = [PlatformType(p) for p in platforms if p in [pt.value for pt in PlatformType]]
        else:
            target_platforms = self.get_available_platforms()
        
        if not target_platforms:
            print("❌ 没有可用的构建平台")
            return {}
        
        print(f"🎯 目标平台: {[p.value for p in target_platforms]}")
        
        # 执行并行构建
        results = self.build_platforms_parallel(target_platforms, build_type, max_workers)
        
        # 保存结果
        self.results.update(results)
        
        return results
    
    def generate_build_report(self, results: Dict[str, BuildResult]) -> str:
        """生成构建报告"""
        report = []
        report.append("# 多平台构建报告")
        report.append(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append("")
        
        # 统计信息
        total_builds = len(results)
        successful_builds = sum(1 for r in results.values() if r.is_success)
        failed_builds = sum(1 for r in results.values() if r.is_failed)
        skipped_builds = sum(1 for r in results.values() if r.status == BuildStatus.SKIPPED)
        
        report.append("## 📊 构建统计")
        report.append(f"- 总构建数: {total_builds}")
        report.append(f"- 成功: {successful_builds}")
        report.append(f"- 失败: {failed_builds}")
        report.append(f"- 跳过: {skipped_builds}")
        report.append("")
        
        # 详细结果
        report.append("## 📋 构建详情")
        for key, result in results.items():
            status_icon = {
                BuildStatus.SUCCESS: "✅",
                BuildStatus.FAILED: "❌",
                BuildStatus.SKIPPED: "⏭️"
            }.get(result.status, "❓")
            
            report.append(f"### {status_icon} {result.platform.value.upper()} ({result.build_type.value})")
            report.append(f"- 状态: {result.status.value}")
            
            if result.duration:
                report.append(f"- 构建时间: {result.duration:.1f}秒")
            
            if result.artifacts:
                report.append(f"- 构建产物:")
                for artifact in result.artifacts:
                    report.append(f"  - {artifact}")
            
            if result.error_message:
                report.append(f"- 错误信息: {result.error_message}")
            
            if result.log_file:
                report.append(f"- 日志文件: {result.log_file}")
            
            report.append("")
        
        # 构建产物汇总
        all_artifacts = []
        for result in results.values():
            if result.artifacts:
                all_artifacts.extend(result.artifacts)
        
        if all_artifacts:
            report.append("## 📦 构建产物汇总")
            for artifact in all_artifacts:
                report.append(f"- {artifact}")
            report.append("")
        
        return "\n".join(report)
    
    def save_build_report(self, results: Dict[str, BuildResult], 
                         filename: str = "build_report.md") -> Path:
        """保存构建报告"""
        report = self.generate_build_report(results)
        report_path = self.project_root / filename
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(report)
        
        print(f"\n📄 构建报告已保存到: {report_path}")
        return report_path
    
    def cleanup_old_logs(self, days: int = 7):
        """清理旧的构建日志"""
        logs_dir = self.project_root / "build_logs"
        if not logs_dir.exists():
            return
        
        cutoff_time = time.time() - (days * 24 * 60 * 60)
        cleaned_count = 0
        
        for log_file in logs_dir.glob("*.log"):
            if log_file.stat().st_mtime < cutoff_time:
                log_file.unlink()
                cleaned_count += 1
        
        if cleaned_count > 0:
            print(f"🧹 清理了 {cleaned_count} 个旧日志文件")

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="多平台构建管理工具")
    parser.add_argument(
        "--platforms", "-p",
        nargs="+",
        choices=[pt.value for pt in PlatformType],
        help="指定要构建的平台（默认构建所有可用平台）"
    )
    parser.add_argument(
        "--build-type", "-t",
        choices=["debug", "release"],
        default="debug",
        help="构建类型（默认：debug）"
    )
    parser.add_argument(
        "--max-workers", "-w",
        type=int,
        default=3,
        help="最大并行构建数（默认：3）"
    )
    parser.add_argument(
        "--report", "-r",
        default="build_report.md",
        help="构建报告文件名（默认：build_report.md）"
    )
    parser.add_argument(
        "--cleanup-logs",
        action="store_true",
        help="构建前清理旧日志文件"
    )
    
    args = parser.parse_args()
    
    builder = MultiPlatformBuilder()
    
    try:
        # 清理旧日志
        if args.cleanup_logs:
            builder.cleanup_old_logs()
        
        # 执行构建
        build_type = BuildType(args.build_type)
        results = builder.build_all(
            build_type=build_type,
            platforms=args.platforms,
            max_workers=args.max_workers
        )
        
        if not results:
            print("❌ 没有执行任何构建任务")
            sys.exit(1)
        
        # 生成报告
        builder.save_build_report(results, args.report)
        
        # 显示总结
        print("\n" + "=" * 60)
        print("📋 构建总结:")
        
        success_count = sum(1 for r in results.values() if r.is_success)
        failed_count = sum(1 for r in results.values() if r.is_failed)
        skipped_count = sum(1 for r in results.values() if r.status == BuildStatus.SKIPPED)
        
        print(f"✅ 成功: {success_count}")
        print(f"❌ 失败: {failed_count}")
        print(f"⏭️ 跳过: {skipped_count}")
        
        if failed_count > 0:
            print(f"\n⚠️ {failed_count} 个平台构建失败，请查看构建报告和日志文件")
            sys.exit(1)
        else:
            print(f"\n🎉 所有构建任务完成！")
            sys.exit(0)
            
    except KeyboardInterrupt:
        print("\n\n⏹️ 构建被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 构建过程出错: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 