/// Web平台版本配置
library web_version_config;

import 'package:package_info_plus/package_info_plus.dart';

class WebVersionConfig {
  /// 获取Web平台版本信息
  static Future<PackageInfo> getVersionInfo() async {
    // 使用 package_info_plus 获取Web版本信息
    return await PackageInfo.fromPlatform();
  }
  
  /// 获取Web应用版本
  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
  
  /// 获取Web缓存版本
  static Future<String> getCacheVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
} 