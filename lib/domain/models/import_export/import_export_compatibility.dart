/// 导入导出兼容性级别
enum CompatibilityLevel {
  /// 完全兼容 - 可以直接导入
  compatible,
  /// 兼容但需要升级 - 需要数据预处理
  compatibleWithUpgrade,
  /// 需要升级应用 - 应用版本过低
  requiresAppUpgrade,
  /// 不兼容 - 无法导入
  incompatible,
}

/// 导入导出兼容性信息
class ImportExportCompatibility {
  /// 兼容性级别
  final CompatibilityLevel level;
  
  /// 源版本
  final String sourceVersion;
  
  /// 目标版本
  final String targetVersion;
  
  /// 兼容性消息
  final String message;
  
  /// 是否可以导入
  final bool canImport;
  
  /// 是否需要数据升级
  final bool requiresDataUpgrade;
  
  /// 是否需要应用升级
  final bool requiresAppUpgrade;
  
  /// 升级路径（如果需要升级）
  final List<String>? upgradePath;

  const ImportExportCompatibility({
    required this.level,
    required this.sourceVersion,
    required this.targetVersion,
    required this.message,
    required this.canImport,
    required this.requiresDataUpgrade,
    required this.requiresAppUpgrade,
    this.upgradePath,
  });

  /// 创建完全兼容的兼容性信息
  factory ImportExportCompatibility.compatible({
    required String sourceVersion,
    required String targetVersion,
    String? message,
  }) {
    return ImportExportCompatibility(
      level: CompatibilityLevel.compatible,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      message: message ?? '版本完全兼容，可以直接导入',
      canImport: true,
      requiresDataUpgrade: false,
      requiresAppUpgrade: false,
    );
  }

  /// 创建需要数据升级的兼容性信息
  factory ImportExportCompatibility.compatibleWithUpgrade({
    required String sourceVersion,
    required String targetVersion,
    String? message,
    List<String>? upgradePath,
  }) {
    return ImportExportCompatibility(
      level: CompatibilityLevel.compatibleWithUpgrade,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      message: message ?? '数据版本较旧，需要升级后才能导入',
      canImport: true,
      requiresDataUpgrade: true,
      requiresAppUpgrade: false,
      upgradePath: upgradePath,
    );
  }

  /// 创建需要应用升级的兼容性信息
  factory ImportExportCompatibility.requiresAppUpgrade({
    required String sourceVersion,
    required String targetVersion,
    String? message,
  }) {
    return ImportExportCompatibility(
      level: CompatibilityLevel.requiresAppUpgrade,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      message: message ?? '数据版本过新，需要升级应用后才能导入',
      canImport: false,
      requiresDataUpgrade: false,
      requiresAppUpgrade: true,
    );
  }

  /// 创建不兼容的兼容性信息
  factory ImportExportCompatibility.incompatible({
    required String sourceVersion,
    required String targetVersion,
    String? message,
  }) {
    return ImportExportCompatibility(
      level: CompatibilityLevel.incompatible,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      message: message ?? '版本不兼容，无法导入',
      canImport: false,
      requiresDataUpgrade: false,
      requiresAppUpgrade: false,
    );
  }

  @override
  String toString() {
    return 'ImportExportCompatibility(level: $level, sourceVersion: $sourceVersion, targetVersion: $targetVersion, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImportExportCompatibility &&
        other.level == level &&
        other.sourceVersion == sourceVersion &&
        other.targetVersion == targetVersion &&
        other.message == message &&
        other.canImport == canImport &&
        other.requiresDataUpgrade == requiresDataUpgrade &&
        other.requiresAppUpgrade == requiresAppUpgrade;
  }

  @override
  int get hashCode {
    return level.hashCode ^
        sourceVersion.hashCode ^
        targetVersion.hashCode ^
        message.hashCode ^
        canImport.hashCode ^
        requiresDataUpgrade.hashCode ^
        requiresAppUpgrade.hashCode;
  }
}
