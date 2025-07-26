import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/models/data_version_definition.dart';
import '../../infrastructure/logging/logger.dart';

/// 数据版本映射服务
class DataVersionMappingService {
  /// 获取应用版本对应的数据版本
  static String getDataVersion(String appVersion) {
    for (final entry in DataVersionDefinition.versions.entries) {
      if (entry.value.appVersions.contains(appVersion)) {
        return entry.key;
      }
    }
    
    AppLogger.warning('未找到应用版本对应的数据版本', 
        tag: 'DataVersionMapping', 
        data: {'appVersion': appVersion});
    
    // 返回最新版本作为默认值
    return DataVersionDefinition.getLatestVersion();
  }
  
  /// 获取当前应用的数据版本
  static Future<String> getCurrentDataVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      return getDataVersion(appVersion);
    } catch (e) {
      AppLogger.error('获取当前应用数据版本失败', 
          error: e, 
          tag: 'DataVersionMapping');
      return DataVersionDefinition.getLatestVersion();
    }
  }
  
  /// 获取数据版本对应的数据库版本
  static int getDatabaseVersion(String dataVersion) {
    return DataVersionDefinition.getDatabaseVersion(dataVersion);
  }
  
  /// 获取当前应用的数据库版本
  static Future<int> getCurrentDatabaseVersion() async {
    final dataVersion = await getCurrentDataVersion();
    return getDatabaseVersion(dataVersion);
  }
  
  /// 获取升级路径
  static List<String> getUpgradePath(String fromVersion, String toVersion) {
    return DataVersionDefinition.getUpgradePath(fromVersion, toVersion);
  }
  
  /// 检查是否需要升级
  static bool needsUpgrade(String fromVersion, String toVersion) {
    return DataVersionDefinition.needsUpgrade(fromVersion, toVersion);
  }
  
  /// 检查数据版本兼容性
  static DataVersionCompatibility checkCompatibility(String backupDataVersion, String currentDataVersion) {
    try {
      final comparison = DataVersionDefinition.compareVersions(backupDataVersion, currentDataVersion);
      
      if (comparison == 0) {
        // 版本相同，完全兼容
        return DataVersionCompatibility.compatible;
      } else if (comparison < 0) {
        // 备份版本较旧，需要升级
        return DataVersionCompatibility.upgradable;
      } else {
        // 备份版本较新，应用需要升级
        return DataVersionCompatibility.appUpgradeRequired;
      }
    } catch (e) {
      AppLogger.error('检查数据版本兼容性失败', 
          error: e, 
          tag: 'DataVersionMapping',
          data: {
            'backupDataVersion': backupDataVersion,
            'currentDataVersion': currentDataVersion,
          });
      return DataVersionCompatibility.incompatible;
    }
  }
  
  /// 获取兼容性描述
  static String getCompatibilityDescription(DataVersionCompatibility compatibility) {
    switch (compatibility) {
      case DataVersionCompatibility.compatible:
        return '完全兼容 - 可以直接恢复';
      case DataVersionCompatibility.upgradable:
        return '兼容但需要升级 - 恢复后会自动升级数据';
      case DataVersionCompatibility.appUpgradeRequired:
        return '需要升级应用 - 请先升级应用到最新版本';
      case DataVersionCompatibility.incompatible:
        return '不兼容 - 无法恢复此备份';
    }
  }
  
  /// 获取所有支持的数据版本
  static List<String> getAllSupportedVersions() {
    return DataVersionDefinition.getAllVersions();
  }
  
  /// 验证数据版本格式
  static bool isValidDataVersion(String version) {
    return DataVersionDefinition.isValidVersion(version);
  }
  
  /// 获取版本信息
  static DataVersionInfo? getVersionInfo(String version) {
    return DataVersionDefinition.getVersionInfo(version);
  }
  
  /// 获取版本特性列表
  static List<String> getVersionFeatures(String version) {
    return DataVersionDefinition.getVersionInfo(version)?.features ?? [];
  }
  
  /// 获取版本描述
  static String getVersionDescription(String version) {
    return DataVersionDefinition.getVersionInfo(version)?.description ?? '未知版本';
  }
}

/// 数据版本兼容性枚举
enum DataVersionCompatibility {
  /// 完全兼容 (C)
  compatible,
  
  /// 兼容但需要升级 (D)
  upgradable,
  
  /// 需要升级应用 (A)
  appUpgradeRequired,
  
  /// 不兼容 (N)
  incompatible;
  
  /// 获取兼容性代码
  String get code {
    switch (this) {
      case DataVersionCompatibility.compatible:
        return 'C';
      case DataVersionCompatibility.upgradable:
        return 'D';
      case DataVersionCompatibility.appUpgradeRequired:
        return 'A';
      case DataVersionCompatibility.incompatible:
        return 'N';
    }
  }
  
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case DataVersionCompatibility.compatible:
        return '完全兼容';
      case DataVersionCompatibility.upgradable:
        return '兼容但要升级';
      case DataVersionCompatibility.appUpgradeRequired:
        return '升级应用';
      case DataVersionCompatibility.incompatible:
        return '不兼容';
    }
  }
  
  /// 从代码创建
  static DataVersionCompatibility fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'C':
        return DataVersionCompatibility.compatible;
      case 'D':
        return DataVersionCompatibility.upgradable;
      case 'A':
        return DataVersionCompatibility.appUpgradeRequired;
      case 'N':
        return DataVersionCompatibility.incompatible;
      default:
        return DataVersionCompatibility.incompatible;
    }
  }
}
