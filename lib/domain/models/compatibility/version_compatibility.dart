/// 版本兼容性数据模型
library version_compatibility;

/// 版本兼容性信息
class VersionCompatibilityInfo {
  /// 版本号
  final String version;

  /// 最小兼容版本
  final String? minCompatibleVersion;

  /// 最大兼容版本
  final String? maxCompatibleVersion;

  /// API兼容性级别
  final CompatibilityLevel apiCompatibility;

  /// 数据兼容性级别
  final CompatibilityLevel dataCompatibility;

  /// 兼容性说明
  final String? description;

  /// 不兼容的功能列表
  final List<String> incompatibleFeatures;

  /// 迁移指导
  final List<MigrationStep> migrationSteps;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  const VersionCompatibilityInfo({
    required this.version,
    this.minCompatibleVersion,
    this.maxCompatibleVersion,
    required this.apiCompatibility,
    required this.dataCompatibility,
    this.description,
    this.incompatibleFeatures = const [],
    this.migrationSteps = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从Map创建实例
  factory VersionCompatibilityInfo.fromMap(Map<String, dynamic> map) {
    return VersionCompatibilityInfo(
      version: map['version'] as String,
      minCompatibleVersion: map['minCompatibleVersion'] as String?,
      maxCompatibleVersion: map['maxCompatibleVersion'] as String?,
      apiCompatibility:
          CompatibilityLevel.fromString(map['apiCompatibility'] as String),
      dataCompatibility:
          CompatibilityLevel.fromString(map['dataCompatibility'] as String),
      description: map['description'] as String?,
      incompatibleFeatures:
          List<String>.from(map['incompatibleFeatures'] ?? []),
      migrationSteps: (map['migrationSteps'] as List<dynamic>? ?? [])
          .map((step) => MigrationStep.fromMap(step as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'minCompatibleVersion': minCompatibleVersion,
      'maxCompatibleVersion': maxCompatibleVersion,
      'apiCompatibility': apiCompatibility.toString(),
      'dataCompatibility': dataCompatibility.toString(),
      'description': description,
      'incompatibleFeatures': incompatibleFeatures,
      'migrationSteps': migrationSteps.map((step) => step.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 检查是否与指定版本兼容
  bool isCompatibleWith(String targetVersion) {
    final target = _parseVersion(targetVersion);

    // 检查最小兼容版本
    if (minCompatibleVersion != null) {
      final minCompatible = _parseVersion(minCompatibleVersion!);
      if (_compareVersions(target, minCompatible) < 0) {
        return false;
      }
    }

    // 检查最大兼容版本
    if (maxCompatibleVersion != null) {
      final maxCompatible = _parseVersion(maxCompatibleVersion!);
      if (_compareVersions(target, maxCompatible) > 0) {
        return false;
      }
    }

    return true;
  }

  /// 获取兼容性报告
  CompatibilityReport getCompatibilityReport(String targetVersion) {
    return CompatibilityReport(
      sourceVersion: version,
      targetVersion: targetVersion,
      isCompatible: isCompatibleWith(targetVersion),
      apiCompatibility: apiCompatibility,
      dataCompatibility: dataCompatibility,
      incompatibleFeatures: incompatibleFeatures,
      migrationSteps: migrationSteps,
      description: description,
    );
  }

  /// 解析版本号为数字列表
  List<int> _parseVersion(String version) {
    return version.split('.').map((part) {
      // 移除非数字字符 (如 1.0.0-beta -> 1.0.0)
      final cleanPart = part.replaceAll(RegExp(r'[^\d].*'), '');
      return int.tryParse(cleanPart) ?? 0;
    }).toList();
  }

  /// 比较两个版本号
  /// 返回: -1 (v1 < v2), 0 (v1 == v2), 1 (v1 > v2)
  int _compareVersions(List<int> v1, List<int> v2) {
    final maxLength = [v1.length, v2.length].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLength; i++) {
      final part1 = i < v1.length ? v1[i] : 0;
      final part2 = i < v2.length ? v2[i] : 0;

      if (part1 < part2) return -1;
      if (part1 > part2) return 1;
    }

    return 0;
  }

  @override
  String toString() {
    return 'VersionCompatibilityInfo(version: $version, apiCompatibility: $apiCompatibility, dataCompatibility: $dataCompatibility)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VersionCompatibilityInfo &&
        other.version == version &&
        other.minCompatibleVersion == minCompatibleVersion &&
        other.maxCompatibleVersion == maxCompatibleVersion &&
        other.apiCompatibility == apiCompatibility &&
        other.dataCompatibility == dataCompatibility;
  }

  @override
  int get hashCode {
    return version.hashCode ^
        minCompatibleVersion.hashCode ^
        maxCompatibleVersion.hashCode ^
        apiCompatibility.hashCode ^
        dataCompatibility.hashCode;
  }
}

/// 兼容性级别枚举
enum CompatibilityLevel {
  /// 完全兼容
  full,

  /// 部分兼容
  partial,

  /// 不兼容
  incompatible,

  /// 未知
  unknown;

  /// 从字符串创建
  static CompatibilityLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'full':
        return CompatibilityLevel.full;
      case 'partial':
        return CompatibilityLevel.partial;
      case 'incompatible':
        return CompatibilityLevel.incompatible;
      default:
        return CompatibilityLevel.unknown;
    }
  }

  @override
  String toString() {
    switch (this) {
      case CompatibilityLevel.full:
        return 'full';
      case CompatibilityLevel.partial:
        return 'partial';
      case CompatibilityLevel.incompatible:
        return 'incompatible';
      case CompatibilityLevel.unknown:
        return 'unknown';
    }
  }

  /// 获取显示名称
  String get displayName {
    switch (this) {
      case CompatibilityLevel.full:
        return '完全兼容';
      case CompatibilityLevel.partial:
        return '部分兼容';
      case CompatibilityLevel.incompatible:
        return '不兼容';
      case CompatibilityLevel.unknown:
        return '未知';
    }
  }

  /// 获取颜色代码
  String get colorCode {
    switch (this) {
      case CompatibilityLevel.full:
        return '#4CAF50'; // 绿色
      case CompatibilityLevel.partial:
        return '#FF9800'; // 橙色
      case CompatibilityLevel.incompatible:
        return '#F44336'; // 红色
      case CompatibilityLevel.unknown:
        return '#9E9E9E'; // 灰色
    }
  }
}

/// 迁移步骤
class MigrationStep {
  /// 步骤标题
  final String title;

  /// 步骤描述
  final String description;

  /// 是否必需
  final bool isRequired;

  /// 预估时间（分钟）
  final int? estimatedMinutes;

  /// 相关文档链接
  final String? documentationUrl;

  const MigrationStep({
    required this.title,
    required this.description,
    this.isRequired = true,
    this.estimatedMinutes,
    this.documentationUrl,
  });

  /// 从Map创建实例
  factory MigrationStep.fromMap(Map<String, dynamic> map) {
    return MigrationStep(
      title: map['title'] as String,
      description: map['description'] as String,
      isRequired: map['isRequired'] as bool? ?? true,
      estimatedMinutes: map['estimatedMinutes'] as int?,
      documentationUrl: map['documentationUrl'] as String?,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isRequired': isRequired,
      'estimatedMinutes': estimatedMinutes,
      'documentationUrl': documentationUrl,
    };
  }

  @override
  String toString() {
    return 'MigrationStep(title: $title, isRequired: $isRequired)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MigrationStep &&
        other.title == title &&
        other.description == description &&
        other.isRequired == isRequired;
  }

  @override
  int get hashCode {
    return title.hashCode ^ description.hashCode ^ isRequired.hashCode;
  }
}

/// 兼容性报告
class CompatibilityReport {
  /// 源版本
  final String sourceVersion;

  /// 目标版本
  final String targetVersion;

  /// 是否兼容
  final bool isCompatible;

  /// API兼容性
  final CompatibilityLevel apiCompatibility;

  /// 数据兼容性
  final CompatibilityLevel dataCompatibility;

  /// 不兼容的功能
  final List<String> incompatibleFeatures;

  /// 迁移步骤
  final List<MigrationStep> migrationSteps;

  /// 描述
  final String? description;

  /// 生成时间
  final DateTime generatedAt;

  CompatibilityReport({
    required this.sourceVersion,
    required this.targetVersion,
    required this.isCompatible,
    required this.apiCompatibility,
    required this.dataCompatibility,
    this.incompatibleFeatures = const [],
    this.migrationSteps = const [],
    this.description,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  /// 获取整体兼容性级别
  CompatibilityLevel get overallCompatibility {
    if (!isCompatible) return CompatibilityLevel.incompatible;

    final levels = [apiCompatibility, dataCompatibility];

    if (levels.every((level) => level == CompatibilityLevel.full)) {
      return CompatibilityLevel.full;
    } else if (levels
        .any((level) => level == CompatibilityLevel.incompatible)) {
      return CompatibilityLevel.incompatible;
    } else {
      return CompatibilityLevel.partial;
    }
  }

  /// 获取必需的迁移步骤
  List<MigrationStep> get requiredMigrationSteps {
    return migrationSteps.where((step) => step.isRequired).toList();
  }

  /// 获取可选的迁移步骤
  List<MigrationStep> get optionalMigrationSteps {
    return migrationSteps.where((step) => !step.isRequired).toList();
  }

  /// 获取预估迁移时间（分钟）
  int get estimatedMigrationTime {
    return migrationSteps
        .where((step) => step.estimatedMinutes != null)
        .map((step) => step.estimatedMinutes!)
        .fold(0, (sum, time) => sum + time);
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'sourceVersion': sourceVersion,
      'targetVersion': targetVersion,
      'isCompatible': isCompatible,
      'apiCompatibility': apiCompatibility.toString(),
      'dataCompatibility': dataCompatibility.toString(),
      'overallCompatibility': overallCompatibility.toString(),
      'incompatibleFeatures': incompatibleFeatures,
      'migrationSteps': migrationSteps.map((step) => step.toMap()).toList(),
      'requiredMigrationSteps': requiredMigrationSteps.length,
      'optionalMigrationSteps': optionalMigrationSteps.length,
      'estimatedMigrationTime': estimatedMigrationTime,
      'description': description,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'CompatibilityReport($sourceVersion -> $targetVersion: ${overallCompatibility.displayName})';
  }
}
