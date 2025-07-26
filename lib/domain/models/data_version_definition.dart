/// 数据版本定义和管理
library data_version_definition;

/// 数据版本信息
class DataVersionInfo {
  /// 数据版本标识
  final String version;

  /// 版本描述
  final String description;

  /// 支持的应用版本列表
  final List<String> appVersions;

  /// 对应的数据库版本
  final int databaseVersion;

  /// 版本特性列表
  final List<String> features;

  /// 创建时间
  final DateTime createdAt;

  DataVersionInfo({
    required this.version,
    required this.description,
    required this.appVersions,
    required this.databaseVersion,
    required this.features,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// 从Map创建实例
  factory DataVersionInfo.fromMap(Map<String, dynamic> map) {
    return DataVersionInfo(
      version: map['version'] as String,
      description: map['description'] as String,
      appVersions: List<String>.from(map['appVersions'] ?? []),
      databaseVersion: map['databaseVersion'] as int,
      features: List<String>.from(map['features'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'description': description,
      'appVersions': appVersions,
      'databaseVersion': databaseVersion,
      'features': features,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'DataVersionInfo(version: $version, description: $description, databaseVersion: $databaseVersion)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataVersionInfo &&
        other.version == version &&
        other.databaseVersion == databaseVersion;
  }

  @override
  int get hashCode {
    return version.hashCode ^ databaseVersion.hashCode;
  }
}

/// 数据版本定义
class DataVersionDefinition {
  static final Map<String, DataVersionInfo> versions = {
    'v1': DataVersionInfo(
      version: 'v1',
      description: '基础数据结构',
      appVersions: ['1.0.0', '1.0.1', '1.0.2'],
      databaseVersion: 5, // 对应 migrations.dart 中的版本 1-5
      features: ['基础作品管理', '字符收集'],
    ),
    'v2': DataVersionInfo(
      version: 'v2',
      description: '练习功能',
      appVersions: ['1.1.0', '1.1.1', '1.2.0'],
      databaseVersion: 10, // 对应 migrations.dart 中的版本 6-10
      features: ['练习模式', '用户偏好设置'],
    ),
    'v3': DataVersionInfo(
      version: 'v3',
      description: '增强作品管理',
      appVersions: ['1.3.0', '1.3.5', '1.3.6'],
      databaseVersion: 15, // 对应 migrations.dart 中的版本 11-15
      features: ['高级作品管理', '元数据支持'],
    ),
    'v4': DataVersionInfo(
      version: 'v4',
      description: '高级功能',
      appVersions: ['1.4.0', '1.5.0'],
      databaseVersion: 18, // 对应 migrations.dart 中的版本 16-18 (当前最新)
      features: ['库管理', '高级导出'],
    ),
  };

  /// 获取所有数据版本
  static List<String> getAllVersions() {
    return versions.keys.toList()..sort();
  }

  /// 获取版本信息
  static DataVersionInfo? getVersionInfo(String version) {
    return versions[version];
  }

  /// 获取最新版本
  static String getLatestVersion() {
    final versionList = getAllVersions();
    return versionList.isNotEmpty ? versionList.last : 'v1';
  }

  /// 检查版本是否存在
  static bool isValidVersion(String version) {
    return versions.containsKey(version);
  }

  /// 获取版本的数据库版本
  static int getDatabaseVersion(String dataVersion) {
    return versions[dataVersion]?.databaseVersion ?? 0;
  }

  /// 获取版本的应用版本列表
  static List<String> getAppVersions(String dataVersion) {
    return versions[dataVersion]?.appVersions ?? [];
  }

  /// 比较两个数据版本的大小
  /// 返回: -1 (v1 < v2), 0 (v1 == v2), 1 (v1 > v2)
  static int compareVersions(String version1, String version2) {
    final allVersions = getAllVersions();
    final index1 = allVersions.indexOf(version1);
    final index2 = allVersions.indexOf(version2);

    if (index1 == -1 || index2 == -1) {
      throw ArgumentError('Invalid version: $version1 or $version2');
    }

    return index1.compareTo(index2);
  }

  /// 检查是否需要升级
  static bool needsUpgrade(String fromVersion, String toVersion) {
    return compareVersions(fromVersion, toVersion) < 0;
  }

  /// 获取升级路径
  static List<String> getUpgradePath(String fromVersion, String toVersion) {
    final allVersions = getAllVersions();
    final fromIndex = allVersions.indexOf(fromVersion);
    final toIndex = allVersions.indexOf(toVersion);

    if (fromIndex == -1 || toIndex == -1) {
      throw ArgumentError('Invalid version: $fromVersion or $toVersion');
    }

    if (fromIndex >= toIndex) {
      return []; // 不需要升级或降级
    }

    return allVersions.sublist(fromIndex, toIndex + 1);
  }
}
