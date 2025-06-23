/// macOS平台版本配置
library macos_version_config;

import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

/// macOS平台版本配置管理
class MacOSVersionConfig {
  /// 获取macOS平台版本信息
  static Future<PackageInfo> getVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      if (kDebugMode) {
        print('macOS版本信息:');
        print('  应用名称: ${packageInfo.appName}');
        print('  Bundle ID: ${packageInfo.packageName}');
        print('  版本: ${packageInfo.version}');
        print('  构建号: ${packageInfo.buildNumber}');
      }
      
      return packageInfo;
    } catch (e) {
      if (kDebugMode) {
        print('获取macOS版本信息失败: $e');
      }
      
      // 返回默认版本信息
      return PackageInfo(
        appName: 'CharasGem',
        packageName: 'com.charasgem.app',
        version: '1.0.0',
        buildNumber: '20250620001',
      );
    }
  }
  
  /// 获取macOS Bundle版本
  static Future<String> getBundleVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
  
  /// 获取macOS Bundle短版本字符串
  static Future<String> getBundleShortVersionString() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
} 