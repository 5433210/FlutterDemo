/// Linux平台版本配置
library linux_version_config;

import 'package:package_info_plus/package_info_plus.dart';

class LinuxVersionConfig {
  /// 获取Linux平台版本信息
  static Future<PackageInfo> getVersionInfo() async {
    // 使用 package_info_plus 获取Linux版本信息
    return await PackageInfo.fromPlatform();
  }
  
  /// 获取Linux应用版本
  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
  
  /// 获取Linux构建号
  static Future<String> getBuildNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
} 