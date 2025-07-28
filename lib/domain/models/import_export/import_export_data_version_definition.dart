import 'package:freezed_annotation/freezed_annotation.dart';

part 'import_export_data_version_definition.freezed.dart';
part 'import_export_data_version_definition.g.dart';

/// 导入导出数据版本信息
@freezed
class ImportExportDataVersionInfo with _$ImportExportDataVersionInfo {
  const factory ImportExportDataVersionInfo({
    /// 数据版本标识
    required String version,
    
    /// 版本描述
    required String description,
    
    /// 支持的应用版本列表
    required List<String> supportedAppVersions,
    
    /// 支持的数据库版本范围 [最小版本, 最大版本]
    required List<int> databaseVersionRange,
    
    /// 版本特性列表
    required List<String> features,
    
    /// 版本发布时间
    DateTime? releaseDate,
    
    /// 是否已弃用
    @Default(false) bool deprecated,
    
    /// 弃用说明
    String? deprecationNote,
  }) = _ImportExportDataVersionInfo;

  factory ImportExportDataVersionInfo.fromJson(Map<String, dynamic> json) =>
      _$ImportExportDataVersionInfoFromJson(json);
}

/// 导入导出数据版本定义
class ImportExportDataVersionDefinition {
  /// 导入导出数据格式版本定义
  static const Map<String, ImportExportDataVersionInfo> versions = {
    'ie_v1': ImportExportDataVersionInfo(
      version: 'ie_v1',
      description: '基础导入导出格式',
      supportedAppVersions: ['1.0.0', '1.1.0'],
      databaseVersionRange: [1, 5],
      features: [
        '基础作品导出',
        '基础集字导出', 
        'JSON格式',
        '简单元数据',
        '基础验证'
      ],
      releaseDate: null,
      deprecated: false,
    ),
    'ie_v2': ImportExportDataVersionInfo(
      version: 'ie_v2',
      description: '增强导入导出格式',
      supportedAppVersions: ['1.1.0', '1.2.0'],
      databaseVersionRange: [6, 10],
      features: [
        'ZIP压缩',
        '图片文件包含',
        '元数据增强',
        '文件校验',
        '压缩级别控制'
      ],
      releaseDate: null,
      deprecated: false,
    ),
    'ie_v3': ImportExportDataVersionInfo(
      version: 'ie_v3',
      description: '完整导入导出格式',
      supportedAppVersions: ['1.2.0', '1.3.0'],
      databaseVersionRange: [11, 15],
      features: [
        '关联数据导出',
        '批量操作',
        '进度监控',
        '增强验证',
        '自定义配置导出'
      ],
      releaseDate: null,
      deprecated: false,
    ),
    'ie_v4': ImportExportDataVersionInfo(
      version: 'ie_v4',
      description: '优化导入导出格式',
      supportedAppVersions: ['1.3.0+'],
      databaseVersionRange: [16, 20],
      features: [
        '增量导入',
        '冲突解决',
        '数据验证',
        '性能优化',
        '流式处理'
      ],
      releaseDate: null,
      deprecated: false,
    ),
  };

  /// 获取所有版本列表
  static List<String> getAllVersions() {
    return versions.keys.toList()..sort();
  }

  /// 获取版本信息
  static ImportExportDataVersionInfo? getVersionInfo(String version) {
    return versions[version];
  }

  /// 检查版本是否存在
  static bool isValidVersion(String version) {
    return versions.containsKey(version);
  }

  /// 获取最新版本
  static String getLatestVersion() {
    final versionList = getAllVersions();
    return versionList.last;
  }

  /// 获取版本的数字表示（用于比较）
  static int getVersionNumber(String version) {
    switch (version) {
      case 'ie_v1':
        return 1;
      case 'ie_v2':
        return 2;
      case 'ie_v3':
        return 3;
      case 'ie_v4':
        return 4;
      default:
        throw ArgumentError('未知的版本: $version');
    }
  }

  /// 比较两个版本
  /// 返回值: -1 表示 version1 < version2, 0 表示相等, 1 表示 version1 > version2
  static int compareVersions(String version1, String version2) {
    final num1 = getVersionNumber(version1);
    final num2 = getVersionNumber(version2);
    return num1.compareTo(num2);
  }

  /// 检查版本1是否小于版本2
  static bool isVersionLessThan(String version1, String version2) {
    return compareVersions(version1, version2) < 0;
  }

  /// 检查版本1是否大于版本2
  static bool isVersionGreaterThan(String version1, String version2) {
    return compareVersions(version1, version2) > 0;
  }

  /// 检查版本1是否等于版本2
  static bool isVersionEqual(String version1, String version2) {
    return compareVersions(version1, version2) == 0;
  }

  /// 获取从源版本到目标版本的升级路径
  static List<String> getUpgradePath(String fromVersion, String toVersion) {
    if (!isValidVersion(fromVersion) || !isValidVersion(toVersion)) {
      throw ArgumentError('无效的版本');
    }

    if (isVersionGreaterThan(fromVersion, toVersion)) {
      throw ArgumentError('不支持版本降级');
    }

    if (isVersionEqual(fromVersion, toVersion)) {
      return [fromVersion];
    }

    final fromNum = getVersionNumber(fromVersion);
    final toNum = getVersionNumber(toVersion);
    
    final path = <String>[];
    for (int i = fromNum; i <= toNum; i++) {
      path.add('ie_v$i');
    }
    
    return path;
  }

  /// 检查版本是否需要升级
  static bool needsUpgrade(String currentVersion, String targetVersion) {
    return isVersionLessThan(currentVersion, targetVersion);
  }

  /// 获取版本支持的应用版本列表
  static List<String> getSupportedAppVersions(String version) {
    final versionInfo = getVersionInfo(version);
    return versionInfo?.supportedAppVersions ?? [];
  }

  /// 获取版本支持的数据库版本范围
  static List<int> getSupportedDatabaseVersionRange(String version) {
    final versionInfo = getVersionInfo(version);
    return versionInfo?.databaseVersionRange ?? [];
  }

  /// 检查应用版本是否支持指定的数据版本
  static bool isAppVersionSupported(String dataVersion, String appVersion) {
    final supportedVersions = getSupportedAppVersions(dataVersion);
    return supportedVersions.contains(appVersion) || 
           supportedVersions.any((v) => v.endsWith('+') && 
                                      appVersion.startsWith(v.substring(0, v.length - 1)));
  }

  /// 检查数据库版本是否支持指定的数据版本
  static bool isDatabaseVersionSupported(String dataVersion, int databaseVersion) {
    final range = getSupportedDatabaseVersionRange(dataVersion);
    if (range.length != 2) return false;
    return databaseVersion >= range[0] && databaseVersion <= range[1];
  }

  /// 获取版本特性列表
  static List<String> getVersionFeatures(String version) {
    final versionInfo = getVersionInfo(version);
    return versionInfo?.features ?? [];
  }

  /// 检查版本是否已弃用
  static bool isVersionDeprecated(String version) {
    final versionInfo = getVersionInfo(version);
    return versionInfo?.deprecated ?? false;
  }

  /// 获取版本弃用说明
  static String? getVersionDeprecationNote(String version) {
    final versionInfo = getVersionInfo(version);
    return versionInfo?.deprecationNote;
  }
}
