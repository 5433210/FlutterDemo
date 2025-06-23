#!/usr/bin/env python3
"""
平台版本管理系统测试脚本
测试新创建的Dart平台管理功能
"""

import subprocess
import sys
import os
import json
from pathlib import Path

def run_dart_test():
    """运行Dart测试代码"""
    
    test_code = '''
import 'dart:io';
import 'lib/platform_management/platform_managers_init.dart';
import 'lib/platform_management/platform_version_manager.dart';

void main() async {
  print('🚀 测试平台版本管理系统');
  
  // 初始化平台管理器
  initializePlatformManagers();
  
  print('\\n📋 支持的平台:');
  final supportedPlatforms = getSupportedPlatformIds();
  for (final platform in supportedPlatforms) {
    print('  ✅ $platform');
  }
  
  print('\\n🔍 检查版本一致性:');
  try {
    final consistencyReport = await checkAllPlatformsVersionConsistency();
    print('  一致性检查: ${consistencyReport["isConsistent"] ? "✅ 通过" : "❌ 失败"}');
    print('  平台数量: ${consistencyReport["totalPlatforms"]}');
    
    if (consistencyReport["versionGroups"] != null) {
      print('  版本分组:');
      final versionGroups = consistencyReport["versionGroups"] as Map<String, dynamic>;
      for (final entry in versionGroups.entries) {
        print('    ${entry.key}: ${entry.value}');
      }
    }
  } catch (e) {
    print('  ❌ 版本一致性检查失败: $e');
  }
  
  print('\\n🔧 验证构建环境:');
  try {
    final buildEnvResults = await validateAllPlatformsBuildEnvironment();
    for (final entry in buildEnvResults.entries) {
      final platform = entry.key;
      final result = entry.value;
      final isValid = result["isValid"] as bool;
      print('  $platform: ${isValid ? "✅ 正常" : "❌ 有问题"}');
      
      if (!isValid) {
        final issues = result["issues"] as List<dynamic>;
        for (final issue in issues) {
          print('    - $issue');
        }
      }
    }
  } catch (e) {
    print('  ❌ 构建环境验证失败: $e');
  }
  
  print('\\n📊 生成版本报告:');
  try {
    final versionReport = await generateAllPlatformsVersionReport();
    final summary = versionReport["summary"] as Map<String, dynamic>;
    
    print('  总平台数: ${summary["totalPlatforms"]}');
    print('  成功平台: ${summary["successfulPlatforms"]}');
    print('  失败平台: ${summary["failedPlatforms"]}');
    print('  版本一致: ${summary["isConsistent"] ? "是" : "否"}');
    
    // 显示各平台状态
    final platforms = versionReport["platforms"] as Map<String, dynamic>;
    for (final entry in platforms.entries) {
      final platform = entry.key;
      final platformData = entry.value as Map<String, dynamic>;
      final status = platformData["status"];
      
      if (status == "success") {
        final versionInfo = platformData["versionInfo"] as Map<String, dynamic>;
        print('  $platform: ${versionInfo["versionName"]} (${versionInfo["versionCode"]})');
      } else {
        print('  $platform: ❌ ${platformData["error"]}');
      }
    }
  } catch (e) {
    print('  ❌ 版本报告生成失败: $e');
  }
  
  print('\\n🎉 平台版本管理系统测试完成!');
}
'''
    
    # 将测试代码写入临时文件
    test_file = Path('test_platform_temp.dart')
    try:
        with open(test_file, 'w', encoding='utf-8') as f:
            f.write(test_code)
        
        print("🧪 运行平台管理系统测试...")
        
        # 运行Dart测试
        result = subprocess.run([
            'flutter', 'dart', 'run', str(test_file)
        ], capture_output=True, text=True, encoding='utf-8')
        
        if result.returncode == 0:
            print("✅ 测试执行成功:")
            print(result.stdout)
        else:
            print("❌ 测试执行失败:")
            print("STDOUT:", result.stdout)
            print("STDERR:", result.stderr)
            
    except Exception as e:
        print(f"❌ 测试运行异常: {e}")
    finally:
        # 清理临时文件
        if test_file.exists():
            test_file.unlink()

def check_platform_files():
    """检查平台配置文件是否存在"""
    print("📁 检查平台配置文件:")
    
    platform_files = {
        'Android': 'android/app/build.gradle.kts',
        'iOS': 'ios/Runner/Info.plist', 
        'Web': 'web/manifest.json',
        'Windows': 'windows/runner/Runner.rc',
        'macOS': 'macos/Runner/Info.plist',
        'Linux': 'linux/CMakeLists.txt',
        'HarmonyOS': 'ohos/entry/src/main/config.json'
    }
    
    for platform, file_path in platform_files.items():
        if os.path.exists(file_path):
            print(f"  ✅ {platform}: {file_path}")
        else:
            print(f"  ❌ {platform}: {file_path} (不存在)")

def main():
    """主函数"""
    print("🔧 平台版本管理系统测试")
    print("=" * 50)
    
    # 检查是否在项目根目录
    if not os.path.exists('pubspec.yaml'):
        print("❌ 错误: 请在Flutter项目根目录运行此脚本")
        return 1
    
    # 检查平台配置文件
    check_platform_files()
    print()
    
    # 运行Dart测试
    run_dart_test()
    
    return 0

if __name__ == '__main__':
    sys.exit(main()) 