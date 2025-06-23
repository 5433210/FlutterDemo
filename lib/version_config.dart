/// 版本配置管理类
/// 统一管理应用版本信息和平台特定版本数据
library version_config;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

// 导入平台特定的版本配置
import 'platform/android_version_config.dart';
import 'platform/ios_version_config.dart';
import 'platform/web_version_config.dart';
import 'platform/windows_version_config.dart';
import 'platform/macos_version_config.dart';
import 'platform/linux_version_config.dart';
import 'platform/ohos_version_config.dart';

/// 版本信息数据类
class VersionInfo {
  /// 主版本号
  final int major;
  
  /// 次版本号
  final int minor;
  
  /// 修订版本号
  final int patch;
  
  /// 预发布标识符 (dev, alpha, beta, rc)
  final String? prerelease;
  
  /// 构建号
  final String buildNumber;
  
  /// Git提交哈希
  final String? gitCommit;
  
  /// Git分支名
  final String? gitBranch;
  
  /// 构建时间
  final DateTime? buildTime;
  
  /// 构建环境
  final String? buildEnvironment;

  const VersionInfo({
    required this.major,
    required this.minor,
    required this.patch,
    this.prerelease,
    required this.buildNumber,
    this.gitCommit,
    this.gitBranch,
    this.buildTime,
    this.buildEnvironment,
  });

  /// 完整版本字符串 (例如: 1.2.3-beta.1-20250620001)
  String get fullVersion {
    final base = '$major.$minor.$patch';
    final pre = prerelease?.isNotEmpty == true ? '-$prerelease' : '';
    return '$base$pre-$buildNumber';
  }

  /// 简化版本字符串 (例如: 1.2.3)
  String get shortVersion => '$major.$minor.$patch';

  /// 是否为预发布版本
  bool get isPrerelease => prerelease?.isNotEmpty == true;

  /// 是否为开发版本
  bool get isDev => prerelease == 'dev';

  /// 是否为正式版本
  bool get isRelease => !isPrerelease;

  @override
  String toString() => fullVersion;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VersionInfo &&
        other.major == major &&
        other.minor == minor &&
        other.patch == patch &&
        other.prerelease == prerelease &&
        other.buildNumber == buildNumber;
  }

  @override
  int get hashCode {
    return major.hashCode ^
        minor.hashCode ^
        patch.hashCode ^
        prerelease.hashCode ^
        buildNumber.hashCode;
  }
}

/// 版本配置管理器
class VersionConfig {
  static VersionConfig? _instance;
  static VersionInfo? _versionInfo;
  
  /// 获取单例实例
  static VersionConfig get instance {
    return _instance ??= VersionConfig._internal();
  }

  VersionConfig._internal();

  /// 初始化版本信息
  static Future<void> initialize() async {
    if (_versionInfo != null) return;
    
    try {
      // 获取平台特定的版本信息
      final platformVersion = await _getPlatformVersionInfo();
      
      // 获取Git信息 (如果可用)
      final gitInfo = await _getGitInfo();
      
      // 解析版本号
      final versionParts = _parseVersion(platformVersion.version);
      final buildNumber = platformVersion.buildNumber;
      
      _versionInfo = VersionInfo(
        major: versionParts['major'] ?? 1,
        minor: versionParts['minor'] ?? 0,
        patch: versionParts['patch'] ?? 0,
        prerelease: versionParts['prerelease'],
        buildNumber: buildNumber,
        gitCommit: gitInfo['commit'],
        gitBranch: gitInfo['branch'],
        buildTime: DateTime.now(), // 实际应用中应该从构建时注入
        buildEnvironment: kDebugMode ? 'debug' : 'release',
      );
    } catch (e) {
      // 使用默认版本信息
      _versionInfo = const VersionInfo(
        major: 1,
        minor: 0,
        patch: 0,
        buildNumber: '20250620001',
      );
    }
  }

  /// 获取版本信息
  static VersionInfo get versionInfo {
    if (_versionInfo == null) {
      throw StateError('VersionConfig not initialized. Call VersionConfig.initialize() first.');
    }
    return _versionInfo!;
  }

  /// 获取平台特定的版本信息
  static Future<PackageInfo> _getPlatformVersionInfo() async {
    if (kIsWeb) {
      return await WebVersionConfig.getVersionInfo();
    } else if (Platform.isAndroid) {
      return await AndroidVersionConfig.getVersionInfo();
    } else if (Platform.isIOS) {
      return await IOSVersionConfig.getVersionInfo();
    } else if (Platform.isWindows) {
      return await WindowsVersionConfig.getVersionInfo();
    } else if (Platform.isMacOS) {
      return await MacOSVersionConfig.getVersionInfo();
    } else if (Platform.isLinux) {
      return await LinuxVersionConfig.getVersionInfo();
    } else if (OHOSVersionConfig.isOHOS) {
      return await OHOSVersionConfig.getVersionInfo();
    } else {
      // 回退到默认的 package_info_plus
      return await PackageInfo.fromPlatform();
    }
  }

  /// 解析版本号字符串
  static Map<String, dynamic> _parseVersion(String version) {
    // 解析格式: 1.2.3-alpha.1+20250620001 或 1.2.3+20250620001
    final regex = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:-([^+]+))?(?:\+(.+))?$');
    final match = regex.firstMatch(version);
    
    if (match == null) {
      return {
        'major': 1,
        'minor': 0,
        'patch': 0,
        'prerelease': null,
      };
    }

    return {
      'major': int.tryParse(match.group(1) ?? '1') ?? 1,
      'minor': int.tryParse(match.group(2) ?? '0') ?? 0,
      'patch': int.tryParse(match.group(3) ?? '0') ?? 0,
      'prerelease': match.group(4), // 预发布标识符
    };
  }

  /// 获取Git信息 (如果可用)
  static Future<Map<String, String?>> _getGitInfo() async {
    try {
      // 在实际应用中，这些信息应该在构建时注入
      // 这里提供一个占位符实现
      return {
        'commit': null, // 实际应从构建时环境变量获取
        'branch': null, // 实际应从构建时环境变量获取
      };
    } catch (e) {
      return {
        'commit': null,
        'branch': null,
      };
    }
  }

  /// 比较版本
  static int compareVersions(VersionInfo a, VersionInfo b) {
    // 比较主版本号
    int result = a.major.compareTo(b.major);
    if (result != 0) return result;

    // 比较次版本号
    result = a.minor.compareTo(b.minor);
    if (result != 0) return result;

    // 比较修订版本号
    result = a.patch.compareTo(b.patch);
    if (result != 0) return result;

    // 比较预发布版本
    if (a.prerelease == null && b.prerelease == null) {
      return a.buildNumber.compareTo(b.buildNumber);
    }
    if (a.prerelease == null) return 1; // 正式版本 > 预发布版本
    if (b.prerelease == null) return -1; // 预发布版本 < 正式版本

    // 比较预发布标识符
    const prereleaseOrder = ['dev', 'alpha', 'beta', 'rc'];
    final aIndex = prereleaseOrder.indexOf(a.prerelease!.split('.')[0]);
    final bIndex = prereleaseOrder.indexOf(b.prerelease!.split('.')[0]);
    
    result = aIndex.compareTo(bIndex);
    if (result != 0) return result;

    // 最后比较构建号
    return a.buildNumber.compareTo(b.buildNumber);
  }

  /// 检查是否需要更新
  static bool needsUpdate(VersionInfo current, VersionInfo remote) {
    return compareVersions(current, remote) < 0;
  }

  /// 获取版本详细信息
  static Map<String, dynamic> getVersionDetails() {
    final info = versionInfo;
    return {
      'version': info.fullVersion,
      'shortVersion': info.shortVersion,
      'major': info.major,
      'minor': info.minor,
      'patch': info.patch,
      'prerelease': info.prerelease,
      'buildNumber': info.buildNumber,
      'isPrerelease': info.isPrerelease,
      'isDev': info.isDev,
      'isRelease': info.isRelease,
      'gitCommit': info.gitCommit,
      'gitBranch': info.gitBranch,
      'buildTime': info.buildTime?.toIso8601String(),
      'buildEnvironment': info.buildEnvironment,
      'platform': _getCurrentPlatform(),
    };
  }

  /// 获取当前平台名称
  static String _getCurrentPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (OHOSVersionConfig.isOHOS) return 'ohos';
    return 'unknown';
  }
}

/// 扩展方法：版本字符串解析
extension VersionStringExtension on String {
  /// 解析版本字符串为 VersionInfo
  VersionInfo? parseAsVersion() {
    final parts = VersionConfig._parseVersion(this);
    if (parts['major'] == null) return null;
    
    return VersionInfo(
      major: parts['major'],
      minor: parts['minor'],
      patch: parts['patch'],
      prerelease: parts['prerelease'],
      buildNumber: '0', // 默认构建号
    );
  }
} 