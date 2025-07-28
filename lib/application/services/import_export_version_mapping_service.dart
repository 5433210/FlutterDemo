import '../../domain/models/import_export/import_export_data_version_definition.dart';

/// 导入导出兼容性类型
enum ImportExportCompatibility {
  /// 完全兼容，直接导入
  compatible,

  /// 兼容但需升级数据格式
  upgradable,

  /// 需要升级应用
  appUpgradeRequired,

  /// 不兼容，无法导入
  incompatible,
}

/// 导入导出版本映射服务
class ImportExportVersionMappingService {
  /// 应用版本 → 导入导出数据版本映射
  static const Map<String, String> appToDataVersionMap = {
    '1.0.0': 'ie_v1',
    '1.1.0': 'ie_v2',
    '1.2.0': 'ie_v3',
    '1.3.0': 'ie_v4',
  };

  /// 数据库版本 → 导入导出数据版本映射
  static const Map<int, String> databaseToDataVersionMap = {
    1: 'ie_v1',
    2: 'ie_v1',
    3: 'ie_v2',
    4: 'ie_v2',
    5: 'ie_v3',
    6: 'ie_v3',
    7: 'ie_v4',
    8: 'ie_v4',
    9: 'ie_v4',
    10: 'ie_v4',
    11: 'ie_v4',
    12: 'ie_v4',
    13: 'ie_v4',
    14: 'ie_v4',
    15: 'ie_v4',
    16: 'ie_v4',
    17: 'ie_v4',
    18: 'ie_v4',
    19: 'ie_v4',
    20: 'ie_v4',
  };

  /// 兼容性矩阵
  /// 行：当前应用支持的数据版本，列：导出文件的数据版本
  static const Map<String, Map<String, ImportExportCompatibility>>
      compatibilityMatrix = {
    'ie_v1': {
      'ie_v1': ImportExportCompatibility.compatible,
      'ie_v2': ImportExportCompatibility.appUpgradeRequired,
      'ie_v3': ImportExportCompatibility.appUpgradeRequired,
      'ie_v4': ImportExportCompatibility.appUpgradeRequired,
    },
    'ie_v2': {
      'ie_v1': ImportExportCompatibility.incompatible,
      'ie_v2': ImportExportCompatibility.compatible,
      'ie_v3': ImportExportCompatibility.appUpgradeRequired,
      'ie_v4': ImportExportCompatibility.appUpgradeRequired,
    },
    'ie_v3': {
      'ie_v1': ImportExportCompatibility.upgradable,
      'ie_v2': ImportExportCompatibility.upgradable,
      'ie_v3': ImportExportCompatibility.compatible,
      'ie_v4': ImportExportCompatibility.upgradable,
    },
    'ie_v4': {
      'ie_v1': ImportExportCompatibility.upgradable,
      'ie_v2': ImportExportCompatibility.upgradable,
      'ie_v3': ImportExportCompatibility.upgradable,
      'ie_v4': ImportExportCompatibility.compatible,
    },
  };

  /// 根据应用版本获取对应的数据版本
  static String getDataVersionForApp(String appVersion) {
    // 首先尝试精确匹配
    if (appToDataVersionMap.containsKey(appVersion)) {
      return appToDataVersionMap[appVersion]!;
    }

    // 检查是否为有效的版本字符串
    if (!_isValidVersionString(appVersion)) {
      return 'ie_v1';
    }

    // 如果没有精确匹配，尝试找到最接近的版本
    final sortedVersions = appToDataVersionMap.keys.toList()..sort();

    for (int i = sortedVersions.length - 1; i >= 0; i--) {
      final version = sortedVersions[i];
      if (_compareVersionStrings(appVersion, version) >= 0) {
        return appToDataVersionMap[version]!;
      }
    }

    // 如果都不匹配，返回最早的版本
    return 'ie_v1';
  }

  /// 根据数据库版本获取对应的数据版本
  static String getDataVersionForDatabase(int databaseVersion) {
    if (databaseToDataVersionMap.containsKey(databaseVersion)) {
      return databaseToDataVersionMap[databaseVersion]!;
    }

    // 如果没有精确匹配，找到最接近的版本
    final sortedVersions = databaseToDataVersionMap.keys.toList()..sort();

    for (int i = sortedVersions.length - 1; i >= 0; i--) {
      final version = sortedVersions[i];
      if (databaseVersion >= version) {
        return databaseToDataVersionMap[version]!;
      }
    }

    // 如果都不匹配，返回最早的版本
    return 'ie_v1';
  }

  /// 获取当前应用支持的最新数据版本
  static String getCurrentDataVersion() {
    return ImportExportDataVersionDefinition.getLatestVersion();
  }

  /// 检查两个数据版本的兼容性
  static ImportExportCompatibility checkCompatibility(
    String exportDataVersion,
    String currentDataVersion,
  ) {
    // 验证版本有效性
    if (!ImportExportDataVersionDefinition.isValidVersion(exportDataVersion) ||
        !ImportExportDataVersionDefinition.isValidVersion(currentDataVersion)) {
      return ImportExportCompatibility.incompatible;
    }

    // 查询兼容性矩阵
    final currentVersionMatrix = compatibilityMatrix[currentDataVersion];
    if (currentVersionMatrix == null) {
      return ImportExportCompatibility.incompatible;
    }

    return currentVersionMatrix[exportDataVersion] ??
        ImportExportCompatibility.incompatible;
  }

  /// 检查导出文件版本与当前应用的兼容性
  static ImportExportCompatibility checkExportCompatibility(
    String exportDataVersion,
    String currentAppVersion,
  ) {
    final currentDataVersion = getDataVersionForApp(currentAppVersion);
    return checkCompatibility(exportDataVersion, currentDataVersion);
  }

  /// 检查是否需要升级
  static bool needsUpgrade(
      String exportDataVersion, String currentDataVersion) {
    final compatibility =
        checkCompatibility(exportDataVersion, currentDataVersion);
    return compatibility == ImportExportCompatibility.upgradable;
  }

  /// 检查是否可以导入
  static bool canImport(String exportDataVersion, String currentDataVersion) {
    final compatibility =
        checkCompatibility(exportDataVersion, currentDataVersion);
    return compatibility == ImportExportCompatibility.compatible ||
        compatibility == ImportExportCompatibility.upgradable;
  }

  /// 获取兼容性描述信息
  static String getCompatibilityDescription(
      ImportExportCompatibility compatibility) {
    switch (compatibility) {
      case ImportExportCompatibility.compatible:
        return '完全兼容，可以直接导入';
      case ImportExportCompatibility.upgradable:
        return '兼容但需要升级数据格式，系统将自动处理';
      case ImportExportCompatibility.appUpgradeRequired:
        return '需要升级应用到更新版本才能导入此文件';
      case ImportExportCompatibility.incompatible:
        return '不兼容，无法导入此文件';
    }
  }

  /// 获取升级建议
  static String getUpgradeSuggestion(
    String exportDataVersion,
    String currentDataVersion,
  ) {
    final compatibility =
        checkCompatibility(exportDataVersion, currentDataVersion);

    switch (compatibility) {
      case ImportExportCompatibility.compatible:
        return '完全兼容，可以直接导入';
      case ImportExportCompatibility.upgradable:
        return '系统将自动升级数据格式从 $exportDataVersion 到 $currentDataVersion，请稍候';
      case ImportExportCompatibility.appUpgradeRequired:
        final exportVersionInfo =
            ImportExportDataVersionDefinition.getVersionInfo(exportDataVersion);
        final supportedVersions = exportVersionInfo?.supportedAppVersions ?? [];
        if (supportedVersions.isNotEmpty) {
          return '请升级应用到 ${supportedVersions.last} 或更高版本';
        }
        return '请升级应用到更新版本';
      case ImportExportCompatibility.incompatible:
        return '此文件格式不受支持，无法导入';
    }
  }

  /// 获取所有支持的数据版本
  static List<String> getAllSupportedDataVersions() {
    return ImportExportDataVersionDefinition.getAllVersions();
  }

  /// 获取版本映射信息
  static Map<String, dynamic> getVersionMappingInfo() {
    return {
      'appVersionMapping': appToDataVersionMap,
      'databaseVersionMapping': databaseToDataVersionMap,
      'compatibilityMatrix': compatibilityMatrix,
      'currentDataVersion': getCurrentDataVersion(),
      'supportedVersions': getAllSupportedDataVersions(),
    };
  }

  /// 比较版本字符串（简单实现）
  static int _compareVersionStrings(String version1, String version2) {
    try {
      final parts1 = version1.split('.').map(int.parse).toList();
      final parts2 = version2.split('.').map(int.parse).toList();

      final maxLength =
          parts1.length > parts2.length ? parts1.length : parts2.length;

      for (int i = 0; i < maxLength; i++) {
        final v1 = i < parts1.length ? parts1[i] : 0;
        final v2 = i < parts2.length ? parts2[i] : 0;

        if (v1 != v2) {
          return v1.compareTo(v2);
        }
      }

      return 0;
    } catch (e) {
      // 如果版本字符串无效，返回 0 表示相等
      return 0;
    }
  }

  /// 检查是否为有效的版本字符串
  static bool _isValidVersionString(String version) {
    if (version.isEmpty) return false;

    try {
      final parts = version.split('.');
      for (final part in parts) {
        int.parse(part);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 验证版本映射配置的一致性
  static bool validateMappingConsistency() {
    try {
      // 检查所有映射的数据版本是否都存在
      for (final dataVersion in appToDataVersionMap.values) {
        if (!ImportExportDataVersionDefinition.isValidVersion(dataVersion)) {
          return false;
        }
      }

      for (final dataVersion in databaseToDataVersionMap.values) {
        if (!ImportExportDataVersionDefinition.isValidVersion(dataVersion)) {
          return false;
        }
      }

      // 检查兼容性矩阵是否完整
      final allVersions = ImportExportDataVersionDefinition.getAllVersions();
      for (final currentVersion in allVersions) {
        if (!compatibilityMatrix.containsKey(currentVersion)) {
          return false;
        }

        final matrix = compatibilityMatrix[currentVersion]!;
        for (final exportVersion in allVersions) {
          if (!matrix.containsKey(exportVersion)) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
