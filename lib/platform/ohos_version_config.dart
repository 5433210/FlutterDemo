/// 鸿蒙OS平台版本配置
library ohos_version_config;

import 'package:package_info_plus/package_info_plus.dart';

class OHOSVersionConfig {
  /// 获取鸿蒙OS平台版本信息
  static Future<PackageInfo> getVersionInfo() async {
    // 使用 package_info_plus 获取鸿蒙OS版本信息
    return await PackageInfo.fromPlatform();
  }
  
  /// 获取鸿蒙OS versionCode
  static Future<String> getVersionCode() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
  
  /// 获取鸿蒙OS versionName
  static Future<String> getVersionName() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
  
  /// 检查是否运行在鸿蒙OS平台
  static bool get isOHOS {
    // 目前Flutter还没有直接的鸿蒙OS平台检测
    // 这里提供一个占位符实现，实际使用时需要根据具体的鸿蒙OS Flutter实现来调整
    try {
      // 可以通过检查特定的鸿蒙OS API或环境变量来判断
      // 例如检查是否存在鸿蒙OS特有的系统属性
      return false; // 临时返回false，实际使用时需要实现具体的检测逻辑
    } catch (e) {
      return false;
    }
  }
} 