/// iOS平台版本配置
library ios_version_config;

import 'package:package_info_plus/package_info_plus.dart';

class IOSVersionConfig {
  /// 获取iOS平台版本信息
  static Future<PackageInfo> getVersionInfo() async {
    // 使用 package_info_plus 获取iOS版本信息
    return await PackageInfo.fromPlatform();
  }
  
  /// 获取iOS CFBundleVersion (构建号)
  static Future<String> getBundleVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
  
  /// 获取iOS CFBundleShortVersionString (版本名称)
  static Future<String> getShortVersionString() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
} 