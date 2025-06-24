/// Linux平台版本配置
library linux_version_config;

import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

class LinuxVersionConfig {
  /// 获取Linux平台版本信息
  static Future<PackageInfo> getVersionInfo() async {
    // 首先尝试从package_info_plus获取
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      // 如果获取到有效信息就返回
      if (packageInfo.version.isNotEmpty && packageInfo.version != 'Unknown') {
        return packageInfo;
      }
    } catch (e) {
      // 如果失败，继续下面的备用方案
    }

    // 备用方案：尝试从version.json文件获取版本信息
    return await _getVersionFromJsonFile();
  }

  /// 从version.json文件获取版本信息
  static Future<PackageInfo> _getVersionFromJsonFile() async {
    try {
      final file = File('version.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final versionData = json.decode(content);
        final version = versionData['version'];
        // final linuxPlatform = versionData['platforms']['linux']; // 保留备用

        final versionString =
            '${version['major']}.${version['minor']}.${version['patch']}';
        final buildNumber = version['build'].toString();

        // 创建一个模拟的PackageInfo
        return _createMockPackageInfo(
          appName: 'Char As Gem',
          version: versionString,
          buildNumber: buildNumber,
        );
      }
    } catch (e) {
      // 如果读取失败，继续使用默认值
    }

    // 最终备用方案：返回默认信息
    return _createMockPackageInfo(
      appName: 'Char As Gem',
      version: '1.0.1',
      buildNumber: '20250623001',
    );
  }

  /// 创建模拟的PackageInfo（由于PackageInfo的构造器是私有的，这里使用一个辅助方法）
  static PackageInfo _createMockPackageInfo({
    required String appName,
    required String version,
    required String buildNumber,
  }) {
    // 由于PackageInfo的构造器是私有的，我们无法直接创建
    // 这里返回一个默认的PackageInfo，并通过其他方式传递版本信息
    return PackageInfo(
      appName: appName,
      packageName: 'com.example.charasgem',
      version: version,
      buildNumber: buildNumber,
    );
  }

  /// 获取Linux应用版本
  static Future<String> getAppVersion() async {
    final packageInfo = await getVersionInfo();
    return packageInfo.version;
  }

  /// 获取Linux构建号
  static Future<String> getBuildNumber() async {
    final packageInfo = await getVersionInfo();
    return packageInfo.buildNumber;
  }
}
