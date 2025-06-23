/// Windows平台版本配置
library windows_version_config;

import 'package:package_info_plus/package_info_plus.dart';

class WindowsVersionConfig {
  /// 获取Windows平台版本信息
  static Future<PackageInfo> getVersionInfo() async {
    // 使用 package_info_plus 获取Windows版本信息
    return await PackageInfo.fromPlatform();
  }
  
  /// 获取Windows文件版本
  static Future<String> getFileVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
  
  /// 获取Windows产品版本
  static Future<String> getProductVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
} 