/// Android平台版本配置
library android_version_config;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Android平台版本配置管理
class AndroidVersionConfig {
  /// 获取Android平台版本信息
  static Future<PackageInfo> getVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      if (kDebugMode) {
        print('Android版本信息:');
        print('  应用名称: ${packageInfo.appName}');
        print('  包名: ${packageInfo.packageName}');
        print('  版本名称: ${packageInfo.version}');
        print('  版本代码: ${packageInfo.buildNumber}');
      }
      
      return packageInfo;
    } catch (e) {
      if (kDebugMode) {
        print('获取Android版本信息失败: $e');
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
  
  /// 获取Android特定的版本代码
  static Future<String> getVersionCode() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
  
  /// 获取Android特定的版本名称
  static Future<String> getVersionName() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
} 