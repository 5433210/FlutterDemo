/// 平台版本管理统一接口
library platform_version_manager;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// 平台版本信息数据类
class PlatformVersionInfo {
  /// 版本名称 (如: 1.0.0)
  final String versionName;
  
  /// 版本代码/构建号
  final String versionCode;
  
  /// 平台标识符
  final String platformId;
  
  /// 平台显示名称
  final String platformDisplayName;
  
  /// 额外的平台特定属性
  final Map<String, dynamic> additionalProperties;
  
  const PlatformVersionInfo({
    required this.versionName,
    required this.versionCode,
    required this.platformId,
    required this.platformDisplayName,
    this.additionalProperties = const {},
  });
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'versionName': versionName,
      'versionCode': versionCode,
      'platformId': platformId,
      'platformDisplayName': platformDisplayName,
      'additionalProperties': additionalProperties,
    };
  }
  
  /// 从Map创建
  factory PlatformVersionInfo.fromMap(Map<String, dynamic> map) {
    return PlatformVersionInfo(
      versionName: map['versionName'] as String,
      versionCode: map['versionCode'] as String,
      platformId: map['platformId'] as String,
      platformDisplayName: map['platformDisplayName'] as String,
      additionalProperties: Map<String, dynamic>.from(
        map['additionalProperties'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
  
  @override
  String toString() => 
      '$platformDisplayName: $versionName ($versionCode)';
}

/// 平台版本管理器抽象基类
abstract class PlatformVersionManager {
  /// 平台标识符
  String get platformId;
  
  /// 平台显示名称
  String get platformDisplayName;
  
  /// 获取当前平台版本信息
  Future<PlatformVersionInfo> getCurrentVersion();
  
  /// 更新平台版本信息
  Future<bool> updateVersion(String versionName, String versionCode);
  
  /// 验证版本格式是否正确
  bool validateVersionFormat(String versionName, String versionCode);
  
  /// 获取平台特定的版本配置路径
  List<String> getConfigFilePaths();
  
  /// 备份当前版本配置
  Future<bool> backupConfig();
  
  /// 恢复版本配置
  Future<bool> restoreConfig();
}

/// 平台版本管理器工厂
class PlatformVersionManagerFactory {
  static final Map<String, PlatformVersionManager> _managers = {};
  
  /// 获取当前平台的版本管理器
  static PlatformVersionManager? getCurrentPlatformManager() {
    final platformId = _getCurrentPlatformId();
    return getManagerForPlatform(platformId);
  }
  
  /// 获取指定平台的版本管理器
  static PlatformVersionManager? getManagerForPlatform(String platformId) {
    return _managers[platformId];
  }
  
  /// 获取所有支持的平台管理器
  static Map<String, PlatformVersionManager> getAllManagers() {
    return Map.unmodifiable(_managers);
  }
  
  /// 注册平台管理器
  static void registerManager(String platformId, PlatformVersionManager manager) {
    _managers[platformId] = manager;
  }
  
  /// 注销平台管理器
  static void unregisterManager(String platformId) {
    _managers.remove(platformId);
  }
  
  /// 获取当前平台ID
  static String _getCurrentPlatformId() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    // 注意：鸿蒙OS检测需要特殊处理
    return 'unknown';
  }
  
  /// 检查平台是否支持
  static bool isPlatformSupported(String platformId) {
    return _managers.containsKey(platformId);
  }
  
  /// 获取支持的平台列表
  static List<String> getSupportedPlatforms() {
    return _managers.keys.toList();
  }
}

/// 版本同步管理器
class VersionSyncManager {
  static final VersionSyncManager _instance = VersionSyncManager._internal();
  static VersionSyncManager get instance => _instance;
  VersionSyncManager._internal();
  
  /// 同步所有平台版本
  Future<Map<String, bool>> syncAllPlatforms(
    String versionName, 
    String versionCode,
  ) async {
    final results = <String, bool>{};
    final managers = PlatformVersionManagerFactory.getAllManagers();
    
    for (final entry in managers.entries) {
      final platformId = entry.key;
      final manager = entry.value;
      
      try {
        final success = await manager.updateVersion(versionName, versionCode);
        results[platformId] = success;
      } catch (e) {
        results[platformId] = false;
      }
    }
    
    return results;
  }
  
  /// 检查所有平台版本一致性
  Future<Map<String, PlatformVersionInfo>> checkVersionConsistency() async {
    final versions = <String, PlatformVersionInfo>{};
    final managers = PlatformVersionManagerFactory.getAllManagers();
    
    for (final entry in managers.entries) {
      final platformId = entry.key;
      final manager = entry.value;
      
      try {
        final version = await manager.getCurrentVersion();
        versions[platformId] = version;
      } catch (e) {
        // 如果获取失败，创建一个错误版本信息
        versions[platformId] = PlatformVersionInfo(
          versionName: 'ERROR',
          versionCode: 'ERROR',
          platformId: platformId,
          platformDisplayName: manager.platformDisplayName,
          additionalProperties: {'error': e.toString()},
        );
      }
    }
    
    return versions;
  }
  
  /// 验证版本一致性
  bool validateConsistency(Map<String, PlatformVersionInfo> versions) {
    if (versions.isEmpty) return true;
    
    final firstVersion = versions.values.first;
    final expectedVersionName = firstVersion.versionName;
    final expectedVersionCode = firstVersion.versionCode;
    
    return versions.values.every((version) =>
        version.versionName == expectedVersionName &&
        version.versionCode == expectedVersionCode);
  }
  
  /// 生成版本一致性报告
  Map<String, dynamic> generateConsistencyReport(
    Map<String, PlatformVersionInfo> versions,
  ) {
    final isConsistent = validateConsistency(versions);
    final versionGroups = <String, List<String>>{};
    
    // 按版本分组
    for (final entry in versions.entries) {
      final platformId = entry.key;
      final version = entry.value;
      final versionKey = '${version.versionName}+${version.versionCode}';
      
      versionGroups.putIfAbsent(versionKey, () => []).add(platformId);
    }
    
    return {
      'isConsistent': isConsistent,
      'totalPlatforms': versions.length,
      'versionGroups': versionGroups,
      'inconsistencies': versionGroups.length > 1 ? versionGroups : null,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
} 